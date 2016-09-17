# coding: utf-8
module Mongoid
  module Voteable
    extend ActiveSupport::Concern

    included do
      field :voted_user_ids, type: Array, default: []
      field :votes_count, type: Integer, default: 0
    end

    def voted_by_user?(user)
      return false if user.blank?
      voted_user_ids.include?(user.id)
    end
  end
end
