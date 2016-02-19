module Mongoid
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    after_update do
      SearchIndexer.perform_later('index', self.class.name, self.id)
    end

    after_save do
      SearchIndexer.perform_later('index', self.class.name, self.id)
    end

    after_destroy do
      SearchIndexer.perform_later('delete', self.class.name, self.id)
    end
  end
end
end

