# coding: utf-8
class Notification::TopicDeleted < Notification::Base
  belongs_to :topic
  delegate :body, to: :topic, prefix: true, allow_nil: true
  delegate :title, to: :topic, prefix: true, allow_nil: true

  def notify_hash
    return {} if self.topic.blank?
    {
        title: "你发布的话题被管理员删除了。",
        content: self.topic_body[0, 30],
        content_path: self.content_path
    }
  end

  def content_path
    return '' if self.topic.blank?
    url_helpers.topic_path(self.topic_id)
  end

end