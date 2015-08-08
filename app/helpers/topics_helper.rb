# coding: utf-8
require 'digest/md5'
module TopicsHelper
  def markdown(text)
    sanitize_markdown(MarkdownTopicConverter.format(text))
  end

  def topic_use_readed_text(state)
    case state
    when true
      t("topics.have_no_new_reply")
    else
      t("topics.has_new_replies")
    end
  end

  def topic_favorite_tag(topic)
    return "" if current_user.blank?
    class_name = ""
    link_title = "收藏"
    if current_user && current_user.favorite_topic_ids.include?(topic.id)
      class_name = "followed"
      link_title = "取消收藏"
    end

    icon = raw(content_tag("i", "", class: "fa fa-bookmark"))

    link_to(raw("#{icon} 收藏"), "#", title: link_title, class: "bookmark #{class_name}", 'data-id' => topic.id)
  end

  def topic_qrcode_tag(topic)
    link_title = "二维码"
    class_name = ""
    icon = raw(content_tag("i", "", class: "fa fa-qrcode"))
    link_to(raw("#{icon} 二维码"), "#",  title: link_title, class: "qrcode #{class_name}", 'data-url' => topic_url(topic))
  end

  def topic_qrcode_pay_tag(topic)
    link_title = "打赏"
    icon = raw(content_tag("i", "", class: "fa fa-money"))
    link_to(raw("#{icon} 打赏"), "#",  title: link_title, class: "pay-qrcode", 'data-url' => (topic.topic_pay_url))
  end


  def topic_follow_tag(topic)
    return "" if current_user.blank?
    return "" if topic.blank?
    return "" if owner?(topic)
    class_name = "follow"
    if topic.follower_ids.include?(current_user.id)
      class_name = "follow followed"
    end
    icon = content_tag("i", "", class: "fa fa-eye")
    followed = class_name == "followed"
    link_to(raw("#{icon} 关注"), "#", 'data-id' => topic.id, 'data-followed' => followed, class: class_name)
  end

  def topic_title_tag(topic)
    return t("topics.topic_was_deleted") if topic.blank?
    link_to(topic.title, topic_path(topic), title: topic.title)
  end

  def topic_excellent_tag(topic)
    return "" if !topic.excellent?
    content_tag(:i,"", title: "精华帖", class: "fa fa-star")
  end

  def render_topic_last_reply_time(topic)
    l((topic.replied_at || topic.created_at), format: :short)
  end

  def render_topic_created_at(topic)
    timeago(topic.created_at, class: "published")
  end

  def render_topic_last_be_replied_time(topic)
    timeago(topic.replied_at)
  end

  def render_topic_node_select_tag(topic)
    return if topic.blank?

    opts = {
        "data-width" => "145px",
        "data-live-search" => "true",
        "data-mobile"=> true,
        "class" => "show-menu-arrow",
        "style" => "width: 145px"
    }
    grouped_collection_select :topic, :node_id, Section.all,
                    :sorted_nodes, :name, :id, :name,
                    {value: topic.node_id, include_blank: true, prompt: "选择节点"}, opts
  end
end
