class QuetionSerializer < BaseSerializer
  attributes :id, :title, :created_at, :updated_at, :answered_at, :answers_count,
             :node_name, :node_id, :last_answer_user_id, :last_answer_user_login,
             :user, :deleted, :excellent, :abilities
             
  def user
    UserSerializer.new(object.user, root: false)
  end
  
  def deleted
    object.deleted_at != nil
  end

  def excellent
    object.excellent == 1
  end
end