class NotifyQuestionJob < ActiveJob::Base
  queue_as :notifications

  def perform(question_id)
    Question.notify_question_created(question_id)
  end
end
