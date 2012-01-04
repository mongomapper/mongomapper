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

      def serializable_attributes
        attributes.keys.map { |k| k.to_s } + ['id'] - ['_id']
      end

      def serializable_hash(options = nil)
        options ||= {}

        options[:only]   = Array.wrap(options[:only]).map { |k| k.to_s }
        options[:except] = Array.wrap(options[:except]).map { |k| k.to_s }

        attribute_names = serializable_attributes

        if options[:only].any?
          attribute_names &= options[:only]
        elsif options[:except].any?
          attribute_names -= options[:except]
        end

        attribute_names += Array.wrap(options[:methods]).map { |m| m.to_s }.select do |method|
          respond_to?(method)
        end

        hash = attribute_names.sort.inject({}) do |hash, name|
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

        serializable_add_includes(options) do |association, records, opts|
          hash[association.to_s] = records.is_a?(Array) ?
            records.map { |r| r.serializable_hash(opts) } :
            records.serializable_hash(opts)
        end

        hash
      end

      def to_xml(options = {}, &block)
        XmlSerializer.new(self, options).serialize(&block)
      end

    private

      def serializable_add_includes(options = {})
        return unless include_associations = options.delete(:include)

        base_only_or_except = { :except => options[:except],
                                :only => options[:only] }

        include_has_options = include_associations.is_a?(Hash)
        associations = include_has_options ? include_associations.keys : Array.wrap(include_associations)

        associations.each do |association|
          records = get_proxy(self.class.associations[association])
          unless records.nil?
            association_options = include_has_options ? include_associations[association] : base_only_or_except
            opts = options.merge(association_options)
            yield(association, records, opts)
          end
        end

        options[:include] = include_associations
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

    # Override default Serializer to use #serializable_hash
    class XmlSerializer < ::ActiveModel::Serializers::Xml::Serializer
      def attributes_hash
        @serializable.serializable_hash(options)
      end

      def serializable_methods
        # Methods are already included in #serializable_hash
        []
      end
    end
  end
end
