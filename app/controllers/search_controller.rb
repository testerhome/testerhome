# coding: utf-8
class SearchController < ApplicationController
  def index
    @topics = Topic.search(
        sort: [
            {updated_at: {order: "desc", ignore_unmapped: true}},
            {excellent:  {order: "desc", ignore_unmapped: true}}
        ],
        query: {
            multi_match: {
                query: params[:q],
                fields: %w(title body^10),
                fuzziness: 2,
                prefix_length: 5,
                operator: :and
            }
        },

        # query: {
        #     filtered: {
        #         query: {
        #             multi_match: {
        #                 fields: %w(title body^10),
        #                 query: params[:q],
        #                 fuzziness: 2,
        #                 prefix_length: 5,
        #                 operator: :and
        #             }
        #         },
        #         filter: {
        #             bool: {
        #                 must: {
        #                     query: {
        #                         multi_match: {
        #                             fields: %w(title body^10),
        #                             query: params[:q],
        #                             fuzziness: 2,
        #                             prefix_length: 5,
        #                             operator: :or
        #                         }
        #                     }
        #                 },
        #                 must_not: {
        #
        #                 },
        #                 should: {
        #
        #                 }
        #             }
        #         }
        #     }
        # },

        highlight: {
            fields: {
                title: {},
                body: {}
            }
        }
    ).paginate(page: params[:page], per_page: 10).records
    @count = @topics.total_entries
  end
end
