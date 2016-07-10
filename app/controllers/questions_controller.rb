# coding: utf-8
class QuestionsController < ApplicationController
  load_and_authorize_resource only: [:new, :edit, :create, :update, :destroy,
                                     :favorite, :unfavorite, :follow, :unfollow,
                                     :close, :open, :action]

  before_action :set_question, only: [:edit, :update, :destroy, :follow,
                                   :unfollow, :close, :open, :action]

  caches_action :feed, :node_feed, expires_in: 1.hours

  def index
    @suggest_questions = Question.without_hide_nodes.suggest.fields_for_list.limit(3).to_a
    @suggest_question_ids = @suggest_questions.collect(&:id)

    @questions = Question.last_actived.without_hide_nodes.where(:_id.nin => @suggest_question_ids)

    @questions = @questions.without_hide_nodes

    if current_user
      @questions = @questions.without_users(current_user.blocked_user_ids)
      @questions = @questions.without_nodes(current_user.blocked_node_ids)
    end

    @questions = @questions.fields_for_list
    @questions = @questions.paginate(page: params[:page], per_page: 25, total_entries: 5000)

    set_seo_meta t("menu.questions"), "#{Setting.app_name}#{t("menu.questions")}"
  end

  def feed
    @questions = Question.without_hide_nodes.recent.without_body.limit(30).includes(:node, :user, :last_answer_user)
    render layout: false
  end

  def feedgood
    @questions = Question.excellent.recent.without_body.limit(30).includes(:node, :user, :last_answer_user)
    render layout: false
  end

  def node
    @node = Node.find(params[:id])
    @questions = @node.questions.last_actived.fields_for_list
    @questions = @questions.includes(:user).paginate(page: params[:page], per_page: 30)
    title = (@node.jobs? or @node.bugs? or @node.opencourses?) ? @node.name : "#{@node.name} &raquo; #{t("menu.questions")}"
    set_seo_meta title, "#{Setting.app_name}#{t("menu.questions")}#{@node.name}", @node.summary
    render action: 'index'
  end

  def node_feed
    @node = Node.find(params[:id])
    @questions = @node.questions.recent.without_body.limit(30)
    render layout: false
  end

  %W(no_answer popular).each do |name|
    define_method(name) do
      @questions = Question.without_hide_nodes.send(name.to_sym).last_actived.fields_for_list.includes(:user)
      @questions = @questions.paginate(page: params[:page], per_page: 30, total_entries: 1500)

      set_seo_meta [t("questions.question_list.#{name}"), t('menu.questions')].join(' &raquo; ')
      render action: 'index'
    end
  end

  def recent
    @questions = Question.without_hide_nodes.recent.fields_for_list.includes(:user)
    @questions = @questions.paginate(page: params[:page], per_page: 30, total_entries: 1500)
    set_seo_meta [t('questions.question_list.recent'), t('menu.questions')].join(' &raquo; ')
    render action: 'index'
  end

  def excellent
    @questions = Question.excellent.recent.fields_for_list.includes(:user)
    @questions = @questions.paginate(page: params[:page], per_page: 30, total_entries: 1500)

    set_seo_meta [t('questions.question_list.excellent'), t('menu.questions')].join(' &raquo; ')
    render action: 'index'
  end

  def show
    @threads = []
    @question = Question.without_body.includes(:user).find(params[:id])

    @question.hits.incr(1)
    @node = @question.node

    @show_raw = params[:raw] == '1'

    @answers = @question.answers.unscoped.without_body.asc(:_id).all
    check_current_user_liked_answers

    check_current_user_status_for_question
    set_special_node_active_menu

    @poll = Poll.for_question(@question.id).first

    @threads.each(&:join)

    set_seo_meta "#{@question.title} &raquo; #{t('menu.questions')}"
  end

  def check_current_user_liked_answers
    return false unless current_user

    # 找出用户 like 过的 Answer，给 JS 处理 like 功能的状态
    @user_liked_answer_ids = []
    @answers.each do |r|
      unless r.liked_user_ids.index(current_user.id).nil?
        @user_liked_answer_ids << r.id
      end
    end
  end

  def check_current_user_status_for_question
    return false unless current_user

    @threads << Thread.new do
      # 通知处理
      current_user.read_question(@question)
    end

    # 是否关注过
    @has_followed = @question.followed?(current_user.id)
    # 是否收藏
    @has_favorited = current_user.favorited_question?(@question.id)
    # 读者是否关注作者
    @has_focused = current_user.followed?(@question.user)
    @has_baned = current_user.blocked_user?(@question.user)
  end

  def set_special_node_active_menu
    case @node.try(:id)
      when Node.jobs_id
        @current = ["/jobs"]
      when Node.bugs_id
        @current = ["/bugs"]
      when Node.opencourse_id
        @current = ["/opencourses"]
    end
  end

  def new
    @question = Question.new
    if !params[:node].blank?
      @question.node_id = params[:node]
      @node = Node.find_by_id(params[:node])
      render_404 if @node.blank?
    end

    set_seo_meta "#{t('questions.post_question')} &raquo; #{t('menu.questions')}"
  end

  def edit
    @node = @question.node
    set_seo_meta "#{t('questions.edit_question')} &raquo; #{t('menu.questions')}"
  end

  def create
    @question = Question.new(question_params)
    @question.user_id = current_user.id
    @question.node_id = params[:node] || question_params[:node_id]

    # # 加入匿名功能
    # if @question.node_id
    #   node = Node.find(@question.node_id)
    #   if node.name.index("匿名")
    #     @question.user_id = 12
    #   end
    # end

    if @question.save
      if poll_params[:save] == "true"
        @poll = @question.build_poll(poll_attrs)
        poll_params[:options].each_with_index do |o, i|
          @poll.options.build({oid: i+1, description: o})
        end
        @poll.save
      end

      question_owner.update_score 5
      redirect_to(question_path(@question.id), notice: t('questions.create_question_success'))
    else
      render action: 'new'
    end
  end

  def preview
    @body = params[:body]

    respond_to do |format|
      format.json
    end
  end

  def update
    @question.admin_editing = true if current_user.admin?
    if current_user.admin? && current_user.id != @question.user_id
      # 管理员且非本帖作者
      @question.modified_admin = current_user
    end

    if @question.lock_node == false || current_user.admin?
      # 锁定接点的时候，只有管理员可以修改节点
      @question.node_id = question_params[:node_id]

      if current_user.admin? && @question.node_id_changed?
        # 当管理员修改节点的时候，锁定节点
        @question.lock_node = true
      end
    end
    @question.title = question_params[:title]
    @question.body = question_params[:body]
    @question.cannot_be_shared = question_params[:cannot_be_shared]

    if @question.save
      redirect_to(question_path(@question.id), notice: t('questions.update_question_success'))
    else
      render action: 'edit'
    end
  end

  def destroy
    if current_user.admin?
      @question.admin_deleting = true
    end
    @question.destroy_by(current_user)
    question_owner.update_score -5
    redirect_to(questions_path, notice: t('questions.delete_question_success'))
  end

  def favorite
    current_user.favorite_question(params[:id])
    render text: '1'
  end

  def unfavorite
    current_user.unfavorite_question(params[:id])
    render text: '1'
  end

  def follow
    @question.push_follower(current_user.id)
    render text: '1'
  end

  def unfollow
    @question.pull_follower(current_user.id)
    render text: '1'
  end

  def action
    case params[:type]
      when 'excellent'
        @question.excellent!
        question_owner.update_score 10
        redirect_to @question, notice: '加精成功。'
      when 'unexcellent'
        @question.unexcellent!
        question_owner.update_score -10
        redirect_to @question, notice: '加精已经取消。'
      when 'ban'
        @question.ban!
        redirect_to @question, notice: '已转移到违规处理区节点。'
    end
  end

  def close
    @question.close!
    redirect_to @question, notice: '话题已关闭，将不再接受任何新的回复。'
  end

  def open
    @question.open!
    redirect_to @question, notice: '话题已重启开启。'
  end

  private

  def set_question
    @question ||= Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:title, :body, :node_id, :cannot_be_shared)
  end

  def question_owner
    User.find_by_id @question.user_id
  end

  def poll_params
    params.require(:poll).permit(:multiple_mode, :public_mode, :expires_in, :save, options: [])
  end

  def poll_attrs
    h = {}
    h[:multiple_mode] = true if poll_params[:multiple_mode]
    h[:public_mode] = true if poll_params[:public_mode]
    h[:expires_in] = poll_params[:expires_in].to_i
    if h[:expires_in] < 0 || h[:expires_in] > 3650
      h[:expires_in] = 0
    end
    return h
  end

end
