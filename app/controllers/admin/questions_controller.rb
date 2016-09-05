module Admin
  class QuestionsController < Admin::ApplicationController
    def index
      @questions = Question.unscoped.desc(:_id).includes(:user).paginate page: params[:page], per_page: 30
    end

    def show
      @question = Question.unscoped.find(params[:id])
    end

    def new
      @question = Question.new
    end

    def edit
      @question = Question.unscoped.find(params[:id])
    end

    def create
      @question = Question.new(params[:question].permit!)

      if @question.save
        redirect_to(admin_questions_path, notice: 'Question was successfully created.')
      else
        render action: 'new'
      end
    end

    def update
      @question = Question.unscoped.find(params[:id])

      if current_user.id != @question.user_id
        # 管理员且非本帖作者
        @question.modified_admin = current_user
      end

      if @question.update_attributes(params[:question].permit!)
        redirect_to(admin_questions_path, notice: 'Question was successfully updated.')
      else
        render action: 'edit'
      end
    end

    def destroy
      @question = Question.unscoped.find(params[:id])
      @question.destroy_by(current_user)
      @question.update_attributes(modified_admin: current_user)
      redirect_to(admin_questions_path)
    end

    def undestroy
      begin
        @question = Question.unscoped.find(params[:id])
        @question.update_attribute(:deleted_at, nil)
        @question.update_attributes(modified_admin: current_user)
      rescue => e
        puts "do nothing"
      ensure
        @question.__elasticsearch__.index_document
      end
      redirect_to(admin_questions_path)
    end

    def suggest
      @question = Question.unscoped.find(params[:id])
      @question.update_attribute(:suggested_at, Time.now)
      @question.update_attributes(modified_admin: current_user)
      CacheVersion.question_last_suggested_at = Time.now
      redirect_to(admin_questions_path, notice: "Question:#{params[:id]} suggested.")
    end

    def unsuggest
      @question = Question.unscoped.find(params[:id])
      @question.update_attribute(:suggested_at, nil)
      @question.update_attributes(modified_admin: current_user)
      CacheVersion.question_last_suggested_at = Time.now
      redirect_to(admin_questions_path, notice: "Question:#{params[:id]} unsuggested.")
    end
  end
end
