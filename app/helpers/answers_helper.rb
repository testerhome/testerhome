# coding: utf-8
module AnswersHelper
  def render_answer_at(answer)
    l(answer.created_at, format: :short)
  end
end
