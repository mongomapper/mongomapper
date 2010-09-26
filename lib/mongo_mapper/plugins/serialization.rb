# encoding: UTF-8
require 'active_model/serializers/json'

module MongoMapper
  module Plugins
    module Serialization
      def self.configure(model)
        model.class_eval do
          include ::ActiveModel::Serializers::JSON
          self.include_root_in_json = false
        end
      end

      module InstanceMethods
        def serializable_hash(options = nil)
          options ||= {}

          unless options[:only]
            options[:methods] = Array(options[:methods]).map(&:to_sym) + [:id]
          end
          options[:except] = Array(options[:except]).map(&:to_sym) + [:_id]
          super options
        end
      end

      module ClassMethods
        def from_json(json)
          self.new.from_json(json)
        end
      end

    end
  end
end
