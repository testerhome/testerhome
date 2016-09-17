module VotesHelper
  # 投票功能
  # 参数
  # voteable - Vote 的对象
  # :cache - 当为 true 时将不会监测用户是否投票过，直接返回未投票过的状态，以用于 cache 的场景
  def voteable_tag(voteable, opts = {})
    return '' if voteable.blank?

    # 没登录，并且也没用用 cache 的时候，直接返回会跳转倒登录的
    return unlogin_voteable_tag(voteable) if opts[:cache].blank? && current_user.blank?

    label = "#{voteable.votes_count}"

    title, state, icon_name =
        if opts[:cache].blank? && voteable.voted_by_user?(current_user)
          ['取消赞同', 'active', 'thumbs-up']
        else
          ['赞同', '', 'thumbs-o-up']
        end
    icon = content_tag('i', '', class: "fa fa-#{icon_name}")
    vote_label = raw "#{icon} <br /> <span>#{label}</span>"

    link_to(vote_label, '#', title: title, 'data-count' => voteable.votes_count,
            'data-state' => state, 'data-type' => voteable.class, 'data-id' => voteable.id,
            class: "voteable #{state}")
  end

  private

  def unlogin_voteable_tag(voteable)
    label = "#{voteable.votes_count}"
    vote_label = raw "<i class='fa fa-thumbs-o-up'></i> <br /> <span>#{label}</span>"
    link_to(vote_label, new_user_session_path, class: '')
  end
end