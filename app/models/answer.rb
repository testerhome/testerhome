# coding: utf-8
require "digest/md5"
class Answer
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::BaseModel
  include Mongoid::CounterCache
  include Mongoid::SoftDelete
  include Mongoid::MarkdownBody
  include Mongoid::Mentionable
  include Mongoid::Voteable
  # include Mongoid::MentionTopic

  field :body
  field :body_html
  field :source
  field :message_id
  # 匿名答复 0 否， 1 是
  field :anonymous, type: Integer, default: 0
  field :action

  belongs_to :user, inverse_of: :answers
  belongs_to :question, inverse_of: :answers, touch: true
  has_many :notifications, class_name: 'Notification::Base', dependent: :delete
  belongs_to :target, polymorphic: true

  counter_cache name: :user, inverse_of: :answers
  counter_cache name: :question, inverse_of: :answers

  index user_id: 1
  index question_id: 1

  delegate :title, to: :question, prefix: true, allow_nil: true
  delegate :login, to: :user, prefix: true, allow_nil: true


  scope :without_system, -> { where(action: nil) }
  scope :fields_for_list, -> { only(:question_id, :_id, :body_html, :updated_at, :created_at) }

  validates_presence_of :body, unless: -> { system_event? }
  validates_uniqueness_of :body, scope: [:question_id, :user_id], message: "不能重复提交。", unless: -> { system_event? }

  validate do
    ban_words = (SiteConfig.ban_words_on_reply || "").split("\n").collect { |word| word.strip }
    if self.body.strip.downcase.in?(ban_words)
      self.errors.add(:body,"请勿回复无意义的内容，如你想收藏或赞这个问答，请用问答后面的功能。")
    end
  end

  # 只有增加 answer 才更新最后 answer
  after_create :update_parent_question
  def update_parent_question
    question.update_last_answer(self)  if self.question.present?
  end

  # 删除的时候也要更新 Question 的 updated_at 以便清理缓存
  after_destroy :update_parent_question_updated_at
  def update_parent_question_updated_at
    if not self.question.blank?
      self.question.update_deleted_last_answer(self)
      true
    end
  end



  after_create :send_notify

  def send_notify
    return if system_event?
    NotifyAnswerJob.perform_later(id)
  end


  def self.notify_answer_created(answer_id)
    answer = Answer.find_by_id(answer_id)
    return if answer.blank?
    question = Question.find_by_id(answer.question_id)
    return if question.blank?

    MessageBus.publish "/questions/#{answer.question_id}", { id: answer.id, user_id: answer.user_id, action: :create }

    notified_user_ids = answer.mentioned_user_ids

    # 给发帖人发回帖通知
    if answer.user_id != question.user_id && !notified_user_ids.include?(question.user_id)
      Notification::QuestionAnswer.create user_id: question.user_id, answer_id: answer.id
      notified_user_ids << question.user_id
    end

    follower_ids = question.follower_ids + (answer.user.try(:follower_ids) || [])
    follower_ids.uniq!

    # 给关注者发通知
    follower_ids.each do |uid|
      # 排除同一个回复过程中已经提醒过的人
      next if notified_user_ids.include?(uid)
      # 排除回帖人
      next if uid == answer.user_id
      puts "Post Notification to: #{uid}"
      Notification::QuestionAnswer.create user_id: uid, answer_id: answer.id
    end
    true
  end

  # 是否热门
  def popular?
    self.votes_count >= 5
  end

  def destroy
    super
    notifications.delete_all
    delete_notifiaction_mentions
  end

  def question_title
    self.question.title
  end

  # 是否是系统事件
  def system_event?
    @system_event ||= action.present?
  end

  def self.create_system_event(opts = {})
    opts[:body] = ''
    opts[:user] ||= User.current
    return false if opts[:action].blank?
    return false if opts[:user].blank?
    self.create(opts)
  end
end
