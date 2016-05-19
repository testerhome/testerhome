class SearchController < ApplicationController
  def index
    search_params = {
        sort: [
            {type_order: {order: "desc", ignore_unmapped: true}},
            {updated_at: {order: "desc", ignore_unmapped: true}},
            {excellent: {order: "desc", ignore_unmapped: true}}
        ],
        query: {
            multi_match: {
                query: params[:q],
                fields: ['title', 'body', 'name', 'login'],
                fuzziness: 2,
                prefix_length: 5,
                operator: :and
            }
        },
        highlight: {
            pre_tags: ["[h]"],
            post_tags: ["[/h]"],
            fields: {title: {}, body: {}, name: {}, login: {}}
        }
    }
    @result = Elasticsearch::Model.search(search_params, [User, Page, Topic]).paginate(page: params[:page], per_page: 30)
  end

  def users
    @users = []
    if params[:q].present?
      @users = User.prefix_match(params[:q])
    end
    render json: @users.collect { |u| { login: u['title'], name: u['name'], avatar_url: u['large_avatar_url'] } },:root => false
  end
end
