# coding: utf-8
class Notification::Question < Notification::Base
  belongs_to :question, class_name: "Question"

  delegate :body, to: :question, prefix: true, allow_nil: true
  delegate :title, to: :question, prefix: true, allow_nil: true

  def notify_hash
    return {} if self.question.blank?
    {
      title: '发表了新问题',
      question_title: self.question_title,
      content: self.question_body[0, 30],
      content_path: self.content_path
    }
  end

  def actor
    self.question.try(:user)
  end

  def content_path
    return '' if self.question.blank?
    url_helpers.question_path(self.question.id)
  end
end
