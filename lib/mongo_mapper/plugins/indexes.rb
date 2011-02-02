# encoding: UTF-8
module MongoMapper
  module Plugins
    module Indexes
      extend ActiveSupport::Concern

      module ClassMethods
        def ensure_index(spec, options={})
          collection.create_index(spec, options)
        end
      end
    end
  end
end