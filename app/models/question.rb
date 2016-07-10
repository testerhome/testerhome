# coding: utf-8
require "auto-space"

CORRECT_CHARS = [
  ['【', '['],
  ['】', ']'],
  ['（', '('],
  ['）', ')']
]

class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::BaseModel
  include Mongoid::SoftDelete
  include Mongoid::CounterCache
  include Mongoid::Likeable
  include Mongoid::MarkdownBody
  include Redis::Objects
  include Mongoid::Mentionable
  include Mongoid::Closeable
  # include Mongoid::MentionTopic

  # 加入 Elasticsearch
  include Mongoid::Searchable

  mapping do
    indexes :title
    indexes :body
    indexes :node_name
  end

  def as_indexed_json(options={})
    {
        title: self.title,
        body: self.full_body,
        node_name: self.node_name,
        updated_at: self.updated_at,
        excellent: self.excellent,
        type_order: self.type_order
    }
  end

  field :title
  field :body
  field :body_html
  field :last_answer_id, type: Integer
  field :answered_at , type: DateTime
  field :source
  field :message_id
  field :answers_count, type: Integer, default: 0
  # 回复过的人的 ids 列表
  field :follower_ids, type: Array, default: []
  field :suggested_at, type: DateTime
  # 最后回复人的用户名 - cache 字段用于减少列表也的查询
  field :last_answer_user_login
  # 节点名称 - cache 字段用于减少列表也的查询
  field :node_name
  # 删除人
  field :who_deleted
  # 用于排序的标记
  field :last_active_mark, type: Integer
  # 是否锁定节点
  field :lock_node, type: Mongoid::Boolean, default: false
  # 精华帖 0 否， 1 是
  field :excellent, type: Integer, default: 0
  field :closed_at , type: DateTime


  # 保留所有权利，禁止转载.默认允许转载
  field :cannot_be_shared, type: Mongoid::Boolean, default: false

  # 修改了帖子的管理员
  belongs_to :modified_admin, class_name: 'User'

  # 临时存储检测用户是否读过的结果
  attr_accessor :read_state, :admin_editing, :admin_deleting

  belongs_to :user, inverse_of: :questions
  counter_cache name: :user, inverse_of: :questions
  belongs_to :node
  counter_cache name: :node, inverse_of: :questions
  belongs_to :last_answer_user, class_name: 'User'
  belongs_to :last_answer, class_name: 'Answer'
  has_many :answers, dependent: :destroy

  has_one :poll, dependent: :destroy

  validates_presence_of :user_id, :title, :body, :node

  index node_id: 1
  index user_id: 1
  index last_active_mark: -1
  index likes_count: 1
  index suggested_at: 1
  index excellent: -1

  counter :hits, default: 0

  delegate :login, to: :user, prefix: true, allow_nil: true
  delegate :body, to: :last_answer, prefix: true, allow_nil: true

  # scopes
  scope :last_actived, -> {  desc(:last_active_mark) }
  # 推荐的话题
  scope :suggest, -> { where(:suggested_at.ne => nil).desc(:suggested_at) }
  scope :fields_for_list, -> { without(:body,:body_html) }
  scope :high_likes, -> { desc(:likes_count, :_id) }
  scope :high_answers, -> { desc(:answers_count, :_id) }
  scope :no_answer, -> { where(answers_count: 0) }
  scope :popular, -> { where(:likes_count.gt => 5) }
  scope :without_node_ids, Proc.new { |ids| where(:node_id.nin => ids) }
  scope :excellent, -> { where(:excellent.gte => 1) }

  scope :without_hide_nodes, -> { where(:node_id.nin => Question.question_index_hide_node_ids) }
  scope :without_nodes, Proc.new { |node_ids|
                        ids = node_ids + self.question_index_hide_node_ids
                        ids.uniq!
                        where(:node_id.nin => ids)
                      }
  scope :without_users, Proc.new { |user_ids| where(:user_id.nin => user_ids) }


  def self.find_by_message_id(message_id)
    where(message_id: message_id).first
  end

  # 排除隐藏的节点
  def self.without_hide_nodes
    where(:node_id.nin => self.question_index_hide_node_ids)
  end

  def related_questions(size = 5)
    self.class.__elasticsearch__.search({
      query: {
        more_like_this: {
          fields: [:title, :body],
          docs: [
            {
              _index: self.class.index_name,
              _type: self.class.document_type,
              _id: id
            }
          ],
          min_term_freq: 2,
          min_doc_freq: 5
        }
      },
      size: size
    }).records.to_a
  end

  def self.without_nodes(node_ids)
    where(:node_id.nin => node_ids)
  end

  def self.without_users(user_ids)
    where(:user_id.nin => user_ids)
  end

  def self.question_index_hide_node_ids
    SiteConfig.node_ids_hide_in_questions_index.to_s.split(",").collect { |id| id.to_i }
  end

  before_save :store_cache_fields
  def store_cache_fields
    self.node_name = self.node.try(:name) || ""
  end
  before_save :auto_space_with_title
  def auto_space_with_title
    self.title.auto_space!
  end

  before_save :auto_correct_title
  def auto_correct_title
    CORRECT_CHARS.each do |chars|
      self.title.gsub!(chars[0], chars[1])
    end
    self.title.auto_space!
  end

  before_save do
    if self.admin_editing == true && self.node_id_changed?
      self.class.notify_question_node_changed(self.id, self.node_id)
    end
  end

  before_destroy do
    if self.admin_deleting == true
      self.class.notify_question_deleted(self.id)
    end
  end

  before_create :init_last_active_mark_on_create
  def init_last_active_mark_on_create
    self.last_active_mark = Time.now.to_i
  end

  after_create do
    NotifyQuestionJob.perform_later(id)
  end

  def followed?(uid)
    follower_ids.include?(uid)
  end

  def push_follower(uid)
    return false if uid == user_id
    return false if followed?(uid)
    push(follower_ids: uid)
    true
  end

  def pull_follower(uid)
    return false if uid == user_id
    pull(follower_ids: uid)
    true
  end

  def update_last_answer(answer, opts = {})
    # answered_at 用于最新回复的排序，如果帖着创建时间在一个月以前，就不再往前面顶了
    return false if answer.blank? && !opts[:force]

    self.last_active_mark = Time.now.to_i if self.created_at > 3.months.ago
    self.answers_count = answers.without_system.count
    self.answered_at = answer.try(:created_at)
    self.last_answer_id = answer.try(:id)
    self.last_answer_user_id = answer.try(:user_id)
    self.last_answer_user_login = answer.try(:user_login)
    self.__elasticsearch__.update_document
    self.save
  end

  # 更新最后更新人，当最后个回帖删除的时候
  def update_deleted_last_answer(deleted_answer)
    return false if deleted_answer.blank?
    return false if self.last_answer_user_id != deleted_answer.user_id

    previous_answer = self.answers.without_system.where(:_id.nin => [deleted_answer.id]).recent.first
    self.update_last_answer(previous_answer, force: true)
  end

  # 删除并记录删除人
  def destroy_by(user)
    return false if user.blank?
    self.update_attribute(:who_deleted,user.login)
    self.destroy
  end

  def destroy
    super
    delete_notifiaction_mentions
  end


  # 所有的回复编号
  def answer_ids
    Rails.cache.fetch([self,"answer_ids"]) do
      # self.answers.only(:_id).map(&:_id)
      answers.only(:_id).map(&:_id).sort
    end
  end

  def floor_of_answer(answer)
    answer_index = answer_ids.index(answer.id)
    answer_index + 1
  end

  def excellent?
    self.excellent >= 1
  end

  def ban!
    update_attributes(lock_node: true, node_id: Node.no_point_id, admin_editing: true)
    Answer.create_system_event(action: 'ban', question_id: self.id)
  end

  def excellent!
    update_attributes(excellent: 1)
    Answer.create_system_event(action: 'excellent', question_id: self.id)
  end

  def unexcellent!
    update_attributes(excellent: 0)
    Answer.create_system_event(action: 'unexcellent', question_id: self.id)
  end

  def self.notify_question_created(question_id)
    question = Question.find_by_id(question_id)
    return if question.blank?

    notified_user_ids = question.mentioned_user_ids

    follower_ids = (question.user.try(:follower_ids) || [])
    follower_ids.uniq!

    # 给关注者发通知
    follower_ids.each do |uid|
      # 排除同一个回复过程中已经提醒过的人
      next if notified_user_ids.include?(uid)
      # 排除回帖人
      next if uid == question.user_id
      puts "Post Notification to: #{uid}"
      Notification::Question.create user_id: uid, question_id: question.id
    end
    true
  end

  def self.notify_question_node_changed(question_id, node_id)
    question = Question.find_by_id(question_id)
    return if question.blank?
    node = Node.find_by_id(node_id)
    return if node.blank?
    Notification::NodeChanged.create user_id: question.user_id, question_id: question_id, node_id: node_id
    return true
  end

  def self.notify_question_deleted(question_id)
    question = Question.find_by_id(question_id)
    return if question.blank?
    Notification::QuestionDeleted.create user_id: question.user_id, question_id: question_id
    return true
  end

  def full_body
    ([self.body] + self.answers.pluck(:body)).join('\n\n')
  end

  def type_order
    1
  end

  def question_pay_url
    return nil if not self.user
    self.user.qrcode_url
  end
end
