# coding: utf-8
class Notification::QuestionAnswer < Notification::Base
  belongs_to :answer, class_name: 'Answer'

  delegate :body, to: :answer, prefix: true, allow_nil: true
  delegate :question_title, to: :answer, prefix: true, allow_nil: true

  def notify_hash
    return {} if self.answer.blank?
    {
      title: '关注的问题有了新回复:',
      question_title: self.answer_question_title,
      content: self.answer_body[0, 30],
      content_path: self.content_path
    }
  end

  def actor
    self.answer.try(:user)
  end

  def content_path
    return '' if self.answer.blank?
    url_helpers.question_path(self.answer.question_id)
  end
end
