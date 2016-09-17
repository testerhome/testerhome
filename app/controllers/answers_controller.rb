class AnswersController < ApplicationController
  load_and_authorize_resource :answer

  before_action :find_question

  def create
    @answer = Answer.new(answer_params)
    @answer.question_id = @question.id
    @answer.user_id = current_user.id

    node = Node.find(@question.node_id)
    if @answer.save
      current_user.read_question(@question)
      @msg = t('questions.answer_success')
      answer_owner.update_score 1
    else
      @msg = @answer.errors.full_messages.join('<br />')
    end
  end

  def index
    last_id = params[:last_id].to_i
    if last_id == 0
      render text: ''
      return
    end

    @answers = Answer.unscoped.where(:question_id => @question.id).where(:id.gt=>last_id).without_body.asc(:id).all
    if current_user
      current_user.read_question(@question)
    end
  end

  def edit
    @answer = Answer.find(params[:id])
  end

  def update
    @answer = Answer.find(params[:id])

    if @answer.update_attributes(answer_params)
      redirect_to(question_path(@answer.question_id), notice: '回答更新成功。')
    else
      render action: 'edit'
    end
  end

  def destroy
    @answer = Answer.find(params[:id])
    if @answer.destroy
      answer_owner.update_score -1
      redirect_to(question_path(@answer.question_id), notice: '回答删除成功。')
    else
      redirect_to(question_path(@answer.question_id), alert: '程序异常，删除失败。')
    end
  end

  protected

  def find_question
    @question = Question.find(params[:question_id])
  end

  def answer_params
    params.require(:answer).permit(:body, :anonymous)
  end

  def answer_owner
    User.find_by_id @answer.user_id
  end
end
