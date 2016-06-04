class SearchController < ApplicationController
  before_action :require_user, only: [:users]

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
    @result = []
    if params[:q].present?
      users = User.prefix_match(params[:q], limit: 100)
      users.sort_by! { |u| current_user.following_ids.index(u['id']) || 9999999999 }
      @result = users.collect { |u| { login: u['title'], name: u['name'], avatar_url: u['large_avatar_url'] } }
    else
      users = current_user.following.limit(10)
      @result = users.collect { |u| { login: u.login, name: u.name, avatar_url: u.large_avatar_url } }
    end

    render json: @result, :root => false
  end
end
