# coding: utf-8
class SearchController < ApplicationController
  def index
    puts params[:q].to_s
    @topics = Topic.search(
        query: {
            multi_match: {
                query: params[:q],
                fields: %w(title body),
                fuzziness: 2
            }
        },
        highlight: {
            fields: {
                title: {},
                body: {}
            }
        }
    ).paginate(page: params[:page], per_page: 15).records

  end
end
