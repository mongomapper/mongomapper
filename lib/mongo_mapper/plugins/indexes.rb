# encoding: UTF-8
module MongoMapper
  module Plugins
    module Indexes
      extend ActiveSupport::Concern

      module ClassMethods
        extend Forwardable
        def_delegators :collection, :ensure_index, :create_index, :drop_index, :drop_indexes
      end
    end
  end
end