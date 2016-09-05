module Admin
  class AnswersController < Admin::ApplicationController
    def index
      @answers = Answer.unscoped.desc(:_id).includes(:question, :user).paginate page: params[:page], per_page: 30
    end

    def show
      @answer = Answer.unscoped.find(params[:id])

      if @answer.question.blank?
        redirect_to admin_answers_path, alert: '问题已经不存在'
      end
    end

    def new
      @answer = Answer.new
    end

    def edit
      @answer = Answer.unscoped.find(params[:id])
    end

    def create
      @answer = Answer.new(params[:answer].permit!)

      if @answer.save
        redirect_to(admin_answers_path, notice: 'Answer was successfully created.')
      else
        render action: 'new'
      end
    end

    def update
      @answer = Answer.unscoped.find(params[:id])

      if @answer.update_attributes(params[:answer].permit!)
        redirect_to(admin_answers_path, notice: 'Answer was successfully updated.')
      else
        render action: 'edit'
      end
    end

    def destroy
      @answer = Answer.unscoped.find(params[:id])
      @answer.destroy
    end
  end
end
