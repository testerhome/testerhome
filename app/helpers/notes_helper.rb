module NotesHelper
  def render_node_topics_count(node)
    node.topics.count
  end

  def render_node_questions_count(node)
    node.questions.count
  end

  def render_node_name(name, id, type = 'topic')
    if type == 'question'
      link_to(name, node_questions_path(id), class: 'node')
    elsif type == 'topic'
      link_to(name, node_topics_path(id), class: 'node')
    else
      raise TypeError('Unavailable node type.')
    end
  end

  def note_title_tag(note, opts = {})
    opts[:limit] ||= 50
    return "" if note.blank?
    return "" if note.title.blank?
    truncate(note.title.gsub('#',''), length: opts[:limit])
  end
end
