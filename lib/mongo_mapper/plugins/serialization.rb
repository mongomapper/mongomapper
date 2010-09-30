# encoding: UTF-8
require 'active_model/serializers/json'
require 'active_model/serializers/xml'

module MongoMapper
  module Plugins
    module Serialization
      def self.configure(model)
        model.class_eval do
          include ::ActiveModel::Serializers::JSON
          include ::ActiveModel::Serializers::Xml
          self.include_root_in_json = false
        end
      end

      module InstanceMethods
        def serializable_attributes
          attributes.keys.map(&:to_s) + ['id'] - ['_id']
        end

        def serializable_hash(options = nil)
          options ||= {}

          options[:only]   = Array.wrap(options[:only]).map(&:to_s)
          options[:except] = Array.wrap(options[:except]).map(&:to_s)

          attribute_names = serializable_attributes

          if options[:only].any?
            attribute_names &= options[:only]
          elsif options[:except].any?
            attribute_names -= options[:except]
          end

          attribute_names += Array.wrap(options[:methods]).map(&:to_s).select do |method|
            respond_to?(method)
          end

          attribute_names.sort.inject({}) do |hash, name|
            value = send(name)
            hash[name] = if value.is_a?(Array)
              value.map {|v| v.respond_to?(:serializable_hash) ? v.serializable_hash : v }
            elsif value.respond_to?(:serializable_hash)
              value.serializable_hash
            else
              value
            end
            hash
          end
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
