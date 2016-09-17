# coding: utf-8
class Notification::QuestionDeleted < Notification::Base
  belongs_to :question
  delegate :body, to: :question, prefix: true, allow_nil: true
  delegate :title, to: :question, prefix: true, allow_nil: true

  def notify_hash
    return {} if self.question.blank?
    {
        title: "你发布的问题被管理员删除了。",
        content: self.question_body[0, 30],
        content_path: self.content_path
    }
  end

  def content_path
    return '' if self.question.blank?
    url_helpers.question_path(self.question_id)
  end

end