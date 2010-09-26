# encoding: UTF-8
require 'active_model/serializers/json'
require 'active_model/serializers/xml'

module MongoMapper
  module Plugins
    module Serialization
      extend ActiveSupport::Concern

      included do
        include ::ActiveModel::Serializers::JSON
        include ::ActiveModel::Serializers::Xml
        self.include_root_in_json = false
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

        def from_xml(xml)
          self.new.from_xml(xml)
        end
      end

    end
  end
end
