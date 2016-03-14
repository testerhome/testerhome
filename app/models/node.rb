class Node < ApplicationRecord
  acts_as_cached version: 1, expires_in: 1.week

  delegate :name, to: :section, prefix: true, allow_nil: true

  has_many :topics
  belongs_to :section

  validates :name, :summary, :section, presence: true
  validates :name, uniqueness: true

  scope :hots, -> { order(topics_count: :desc) }
  scope :sorted, -> { order(sort: :desc) }

  after_save :update_cache_version
  after_destroy :update_cache_version

  def update_cache_version
    # 记录节点变更时间，用于清除缓存
    CacheVersion.section_node_updated_at = Time.now
  end

  # Markdown 转换过后的 HTML
  def summary_html
    Rails.cache.fetch("#{cache_key}/summary_html") do
      MarkdownTopicConverter.convert(summary)
    end
  end

  # 是否为 jobs 节点
  def jobs?
    id == self.class.jobs_id
  end

  def self.new_topic_dropdowns
    return [] if SiteConfig.new_topic_dropdown_node_ids.blank?
    node_ids = SiteConfig.new_topic_dropdown_node_ids.split(',').uniq.take(5)
    where(id: node_ids)
  end

  def self.jobs_id
    19
  end

  def self.bugs_id
    47
  end

  def self.no_point_id
    55
  end

  def self.opencourse_id
    67
  end

end
