# coding: utf-8
class Notification::NodeChanged < Notification::Base
  belongs_to :topic, class_name: "Topic"
  belongs_to :question, class_name: "Question"
  belongs_to :node

  delegate :name, to: :node, allow_nil: true, prefix: true

  def notify_hash
    return {} if self.topic.blank?
    return {} if self.question.blank?
    if self.topic
      {
          title: "你发布的话题被管理员移动到了 #{self.node_name} 节点。",
          content: '',
          content_path: self.content_path
      }
    else
      {
          title: "你发布的问题被管理员移动到了 #{self.node_name} 节点。",
          content: '',
          content_path: self.content_path
      }
    end
  end

  def content_path
    return '' if self.topic.blank?
    url_helpers.topic_path(self.topic_id)
  end
end