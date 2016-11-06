# coding: utf-8
class Notification::TopicDeleted < Notification::Base
  belongs_to :topic
  delegate :body, to: :topic, prefix: true, allow_nil: true
  delegate :title, to: :topic, prefix: true, allow_nil: true

  def notify_hash
    return {title: "你发布的话题被管理员删除了。", content: "请注意查看论坛须知。", content_path: "markdown"} if self.topic.blank?
    {
        title: "你发布的话题被管理员删除了。",
        content: self.topic_body[0, 30],
        content_path: self.content_path
    }
  end

  def content_path
    return 'markdown'
  end

end