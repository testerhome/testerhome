# coding: utf-8
class TopicsController < ApplicationController
  load_and_authorize_resource only: [:new, :edit, :create, :update, :destroy,
                                     :favorite, :unfavorite, :follow, :unfollow, :suggest, :unsuggest, :ban]
  caches_action :feed, :node_feed, expires_in: 1.hours

  def index
    @suggest_topics = Topic.without_hide_nodes.suggest.fields_for_list.limit(3).to_a
    @suggest_topic_ids = @suggest_topics.collect(&:id)

    @topics = Topic.last_actived.without_hide_nodes.where(:_id.nin => @suggest_topic_ids)

    @topics = @topics.without_hide_nodes

    if current_user
      @topics = @topics.without_users(current_user.blocked_user_ids)
      @topics = @topics.without_nodes(current_user.blocked_node_ids)
    end

    @topics = @topics.fields_for_list
    @topics = @topics.paginate(page: params[:page], per_page: 25, total_entries: 5000)

    set_seo_meta t("menu.topics"), "#{Setting.app_name}#{t("menu.topics")}"
  end

  def feed
    @topics = Topic.without_hide_nodes.recent.without_body.limit(30).includes(:node, :user, :last_reply_user)
    render layout: false
  end

  def feedgood
    @topics = Topic.excellent.recent.without_body.limit(30).includes(:node, :user, :last_reply_user)
    render layout: false
  end

  def node
    @node = Node.find(params[:id])
    @topics = @node.topics.last_actived.fields_for_list
    @topics = @topics.includes(:user).paginate(page: params[:page], per_page: 30)
    title = (@node.jobs? or @node.bugs? or @node.opencourses?) ? @node.name : "#{@node.name} &raquo; #{t("menu.topics")}"
    set_seo_meta title, "#{Setting.app_name}#{t("menu.topics")}#{@node.name}", @node.summary
    render action: 'index'
  end

  def node_feed
    @node = Node.find(params[:id])
    @topics = @node.topics.recent.without_body.limit(30)
    render layout: false
  end

  %W(no_reply popular).each do |name|
    define_method(name) do
      @topics = Topic.without_hide_nodes.send(name.to_sym).last_actived.fields_for_list.includes(:user)
      @topics = @topics.paginate(page: params[:page], per_page: 30, total_entries: 1500)

      set_seo_meta [t("topics.topic_list.#{name}"), t('menu.topics')].join(' &raquo; ')
      render action: 'index'
    end
  end

  def recent
    @topics = Topic.without_hide_nodes.recent.fields_for_list.includes(:user)
    @topics = @topics.paginate(page: params[:page], per_page: 30, total_entries: 1500)
    set_seo_meta [t('topics.topic_list.recent'), t('menu.topics')].join(' &raquo; ')
    render action: 'index'
  end

  def excellent
    @topics = Topic.excellent.recent.fields_for_list.includes(:user)
    @topics = @topics.paginate(page: params[:page], per_page: 30, total_entries: 1500)

    set_seo_meta [t('topics.topic_list.excellent'), t('menu.topics')].join(' &raquo; ')
    render action: 'index'
  end

  def show
    @threads = []
    @topic = Topic.without_body.includes(:user).find(params[:id])

    @threads << Thread.new do
      @topic.hits.incr(1)
    end
    @threads << Thread.new do
      @node = @topic.node
    end

    @show_raw = params[:raw] == '1'

    @threads << Thread.new do
      @replies = @topic.replies.unscoped.without_body.asc(:_id).all
      check_current_user_liked_replies
    end

    check_current_user_status_for_topic
    set_special_node_active_menu

    @poll = Poll.for_topic(@topic.id).first

    @threads.each(&:join)

    set_seo_meta "#{@topic.title} &raquo; #{t('menu.topics')}"
  end

  def check_current_user_liked_replies
    return false unless current_user

    # 找出用户 like 过的 Reply，给 JS 处理 like 功能的状态
    @user_liked_reply_ids = []
    @replies.each do |r|
      unless r.liked_user_ids.index(current_user.id).nil?
        @user_liked_reply_ids << r.id
      end
    end
  end

  def check_current_user_status_for_topic
    return false unless current_user

    @threads << Thread.new do
      # 通知处理
      current_user.read_topic(@topic)
    end

    # 是否关注过
    @has_followed = @topic.followed?(current_user.id)
    # 是否收藏
    @has_favorited = current_user.favorited_topic?(@topic.id)
    # 读者是否关注作者
    @has_focused = current_user.followed?(@topic.user)
    @has_baned = current_user.blocked_user?(@topic.user)
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
    @topic = Topic.new
    if !params[:node].blank?
      @topic.node_id = params[:node]
      @node = Node.find_by_id(params[:node])
      render_404 if @node.blank?
    end

    set_seo_meta "#{t('topics.post_topic')} &raquo; #{t('menu.topics')}"
  end

  def edit
    @topic = Topic.find(params[:id])
    @node = @topic.node

    set_seo_meta "#{t('topics.edit_topic')} &raquo; #{t('menu.topics')}"
  end

  def create
    @topic = Topic.new(topic_params)
    @topic.user_id = current_user.id
    @topic.node_id = params[:node] || topic_params[:node_id]

    # 加入匿名功能
    if @topic.node_id
      node = Node.find(@topic.node_id)
      if node.name.index("匿名")
        @topic.user_id = 12
      end
    end

    if @topic.save
      if poll_params[:save] == "true"
        @poll = @topic.build_poll(poll_attrs)
        poll_params[:options].each_with_index do |o, i|
          @poll.options.build({oid: i+1, description: o})
        end
        @poll.save
      end

      topic_owner.update_score 5
      redirect_to(topic_path(@topic.id), notice: t('topics.create_topic_success'))
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
    @topic = Topic.find(params[:id])

    if current_user.admin?
      @topic.admin_editing = true
    end

    if current_user.admin? && current_user.id != @topic.user_id
      # 管理员且非本帖作者
      @topic.modified_admin = current_user
    end

    if @topic.lock_node == false || current_user.admin?
      # 锁定接点的时候，只有管理员可以修改节点
      @topic.node_id = topic_params[:node_id]

      if current_user.admin? && @topic.node_id_changed?
        # 当管理员修改节点的时候，锁定节点
        @topic.lock_node = true
      end
    end
    @topic.title = topic_params[:title]
    @topic.body = topic_params[:body]
    @topic.cannot_be_shared = topic_params[:cannot_be_shared]

    if @topic.save
      redirect_to(topic_path(@topic.id), notice: t('topics.update_topic_success'))
    else
      render action: 'edit'
    end
  end

  def destroy
    @topic = Topic.find(params[:id])
    if current_user.admin?
      @topic.admin_deleting = true
    end
    @topic.destroy_by(current_user)
    topic_owner.update_score -5
    redirect_to(topics_path, notice: t('topics.delete_topic_success'))
  end

  def favorite
    current_user.favorite_topic(params[:id])
    render text: '1'
  end

  def unfavorite
    current_user.unfavorite_topic(params[:id])
    render text: '1'
  end

  def follow
    @topic = Topic.find(params[:id])
    @topic.push_follower(current_user.id)
    render text: '1'
  end

  def unfollow
    @topic = Topic.find(params[:id])
    @topic.pull_follower(current_user.id)
    render text: '1'
  end

  def suggest
    @topic = Topic.find(params[:id])
    @topic.update_attributes(excellent: 1)
    topic_owner.update_score 10
    if current_user.admin?
      @topic.update_attributes(modified_admin: current_user)
    end
    redirect_to @topic, success: '加精成功。'
  end

  def unsuggest
    @topic = Topic.find(params[:id])
    @topic.update_attribute(:excellent, 0)
    topic_owner.update_score -10
    if current_user.admin?
      @topic.update_attributes(modified_admin: current_user)
    end
    redirect_to @topic, success: '加精已经取消。'
  end


  def ban
    @topic = Topic.find(params[:id])
    @topic.update_attribute(:node_id, Node.no_point_id)
    if current_user.admin?
      @topic.update_attributes(modified_admin: current_user)
    end
    redirect_to @topic, success: '已转移到 NoPoint 节点。'
  end

  private

  def topic_params
    params.require(:topic).permit(:title, :body, :node_id, :cannot_be_shared)
  end

  def topic_owner
    User.find_by_id @topic.user_id
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
