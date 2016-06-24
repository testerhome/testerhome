# coding: utf-8
module Mongoid
  module Closeable
    extend ActiveSupport::Concern

    included do
    end

    def closed?
      closed_at.present?
    end

    def close!
      self.closed_at = Time.now
      self.save
      Reply.create_system_event(action: 'close', topic_id: self.id)
    end

    def open!
      self.closed_at = nil
      self.save
      Reply.create_system_event(action: 'reopen', topic_id: self.id)
    end
  end
end
