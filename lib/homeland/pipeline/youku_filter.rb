module Homeland
  class Pipeline
    class YoukuFilter < HTML::Pipeline::TextFilter
      YOUKU_URL_REGEXP = /(\s|^|<div>|<br>)(https?:\/\/)(\w+\.)?(youku\.com\/v_show\/id_)(.*)\.html\S*/

      def call
        @text.gsub(YOUKU_URL_REGEXP) do
          youku_id = $5
          close_tag = $1 if ["<br>", "<div>"].include? $1
          wmode = context[:video_wmode]
          autoplay = context[:video_autoplay] || false
          hide_related = context[:video_hide_related] || false
          src = "http://player.youku.com/embed/#{youku_id}"
          params = []
          params << "wmode=#{wmode}" if wmode
          params << "autoplay=1" if autoplay
          params << "rel=0" if hide_related
          src += "?#{params.join '&'}" unless params.empty?

          %{#{close_tag}<span class="embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="#{src}" allowfullscreen></iframe></span>}
        end
      end
    end
  end
end