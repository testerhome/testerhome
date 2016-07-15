class NotifyAnswerJob < ActiveJob::Base
  queue_as :notifications

  def perform(answer_id)
    Answer.notify_answer_created(answer_id)
  end
end
