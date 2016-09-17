class AnswerDetailSerializer < AnswerSerializer
  delegate :title, to: :topic, allow_nil: true

  attributes :body, :question_title
end