# coding: utf-8
require 'digest/md5'
module QuestionsHelper
  def markdown(text)
    sanitize_markdown(MarkdownTopicConverter.format(text))
  end

  def question_use_readed_text(state)
    case state
    when true
      t("questions.have_no_new_answer")
    else
      t("questions.has_new_answers")
    end
  end

  def question_favorite_tag(question, opts = {})
    return "" if current_user.blank?
    opts[:class] ||= ""
    class_name = ""
    link_title = "收藏"
    if current_user && current_user.favorite_question_ids.include?(question.id)
      class_name = 'active'
      link_title = "取消收藏"
    end

    icon = raw(content_tag("i", "", class: "fa fa-bookmark"))

    link_to(raw("#{icon} 收藏"), '#', title: link_title, class: "#{opts[:class]} bookmark #{class_name}", 'data-id' => question.id)
  end

  def question_qrcode_tag(question)
    link_title = "二维码"
    class_name = ""
    icon = raw(content_tag("i", "", class: "fa fa-qrcode"))
    link_to(raw("#{icon} 二维码"), "#",  title: link_title, class: "qrcode #{class_name}", 'data-url' => question_url(question))
  end

  def question_qrcode_pay_tag(question)
    link_title = "打赏"
    icon = raw(content_tag("i", "", class: "fa fa-money"))
    link_to(raw("#{icon} 打赏"), "#",  title: link_title, class: "btn pay-qrcode", 'data-url' => (question.question_pay_url))
  end

  def question_follow_tag(question, opts = {})
    return '' if current_user.blank?
    return '' if question.blank?
    return '' if owner?(question)
    opts[:class] ||= ""
    class_name = 'follow'
    followed = false
    if question.follower_ids.include?(current_user.id)
      class_name = 'follow active'
      followed = true
    end
    class_name = "#{opts[:class]} #{class_name}"
    icon = content_tag('i', '', class: 'fa fa-eye')
    link_to(raw("#{icon} 关注"), '#', 'data-id' => question.id, class: class_name)
  end

  def question_title_tag(question, opts = {})
    return t('questions.question_was_deleted') if question.blank?
    if opts[:answer]
      index = question.floor_of_answer(opts[:answer])
      path = question_path(question, anchor: "answer#{index}")
    else
      path = question_path(question)
    end
    link_to(question.title, path, title: question.title)
  end

  def question_excellent_tag(question)
    return "" if !question.excellent?
    content_tag(:i,"", title: "精华问题", class: "fa fa-star")
  end

  def question_closed_tag(question)
    return "" if !question.closed?
    content_tag(:i, '', title: '问题已解决', class: 'fa fa-check', data: { toggle: 'tooltip' })
  end

  def render_question_last_answer_time(question)
    l((question.answered_at || question.created_at), format: :short)
  end

  def render_question_created_at(question)
    timeago(question.created_at, class: "published")
  end

  def render_question_last_be_answered_time(question)
    timeago(question.answered_at)
  end

  def render_question_node_select_tag(question)
    return if question.blank?

    opts = {
        "data-width" => "140px",
        "data-live-search" => "true",
        class: "show-menu-arrow"
    }

    if question.node_id == Node.no_point_id and !admin?
      # 非管理员，屏蔽帖只能选屏蔽节点
      nodes = :no_point_nodes
    elsif current_user.admin?
      # 管理员，可以选所有节点（包括屏蔽节点）
      nodes = :all_sorted_nodes
    else
      # 非管理员非屏蔽帖，可以选除屏蔽节点外所有节点
      nodes = :sorted_nodes
    end

    grouped_collection_select :question, :node_id, Section.all,
                              nodes, :name, :id, :name,
                              { value: question.node_id, prompt: "选择节点"}, opts

  end

end
