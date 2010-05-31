# encoding: UTF-8
module MongoMapper
  module Plugins
    module Clone
      module InstanceMethods
        def initialize_copy(other)
          @_new       = true
          @_destroyed = false
          default_id_value({})
          other.attributes.clone.except(:_id).each do |key, value|
            self[key] = value.duplicable? ? value.clone : value
          end
        end
      end
    end
  end
end