xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title t("rss.recent_node_questions_title", name: Setting.app_name, node_name: @node.name)
    xml.link root_url
    xml.description t("rss.recent_node_questions_description", name: Setting.app_name, node_name: @node.name)
    for question in @questions
      xml.item do
        xml.title question.title
        xml.description raw(question.body_html)
        xml.author question.user.login
        xml.pubDate question.created_at.strftime("%a, %d %b %Y %H:%M:%S %z")
        xml.link question_url(question)
        xml.guid question_url(question)
      end
    end
  end
end
