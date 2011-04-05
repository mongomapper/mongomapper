# encoding: UTF-8
module MongoMapper
  module Plugins
    module Clone
      extend ActiveSupport::Concern

      module InstanceMethods
        def initialize_copy(other)
          @_new       = true
          @_destroyed = false
          default_id_value
          associations.each do |name, association|
            instance_variable_set(association.ivar, nil)
          end
          self.attributes = Hash[
            other.attributes.clone.except(:_id).map do |entry|
              key, value = entry
              [key, value.duplicable? ? value.clone : value]
            end
          ]
        end
      end
    end
  end
end
