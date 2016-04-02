module Mongoid
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    after_update do
      SearchIndexer.perform('index', self.class.name, self.id)
    end

    after_save do
      SearchIndexer.perform('index', self.class.name, self.id)
    end

    after_destroy do
      Rails.logger.error("perform_later('delete')")
      SearchIndexer.perform('delete', self.class.name, self.id)
    end
  end
end
end

