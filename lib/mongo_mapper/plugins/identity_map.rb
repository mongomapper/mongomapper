# encoding: UTF-8
require 'set'

module MongoMapper
  module Plugins
    module IdentityMap
      extend ActiveSupport::Concern

      def self.enabled=(flag)
        Thread.current[:mongo_mapper_identity_map_enabled] = flag
      end

      def self.enabled
        Thread.current[:mongo_mapper_identity_map_enabled]
      end

      def self.enabled?
        enabled == true
      end

      def self.repository
        Thread.current[:mongo_mapper_identity_map] ||= {}
      end

      def self.clear
        repository.clear
      end

      def self.include?(document)
        repository.key?(IdentityMap.key(document.class, document._id))
      end

      def self.key(model, id)
        "#{model.single_collection_root.name}:#{id}"
      end

      def self.use
        old, self.enabled = enabled, true

        yield if block_given?
      ensure
        self.enabled = old
        clear
      end

      def self.without
        old, self.enabled = enabled, false

        yield if block_given?
      ensure
        self.enabled = old
      end

      module ClassMethods
        # Private - Looks for a document in the identity map
        def get_from_identity_map(id)
          IdentityMap.repository[IdentityMap.key(self, id)]
        end

        def query(opts={})
          super.tap do |query|
            query.identity_map = self if Thread.current[:mongo_mapper_identity_map_enabled]
          end
        end

        def remove_documents_from_map(*documents)
          documents.flatten.compact.each do |document|
            document.remove_from_identity_map
          end
        end

        def load(attrs, with_cast = false)
          return super unless Thread.current[:mongo_mapper_identity_map_enabled]
          return nil unless attrs
          document = get_from_identity_map(attrs['_id'])

          if !document
            document = super
            document.add_to_identity_map
          end

          document
        end
      end

      def save(*args)
        super.tap { |result| add_to_identity_map if result }
      end

      def delete
        super.tap { remove_from_identity_map }
      end

      def add_to_identity_map
        if IdentityMap.enabled?
          key = IdentityMap.key(self.class, _id)
          IdentityMap.repository[key] = self
        end
      end

      def remove_from_identity_map
        if IdentityMap.enabled?
          key = IdentityMap.key(self.class, _id)
          IdentityMap.repository.delete(key)
        end
      end
    end
  end
end

module PluckyMethods
  module ClassMethods
    extend ActiveSupport::Concern

    included do
      attr_accessor :identity_map

      # Ensure that these aliased methods in plucky also get overridden.
      alias_method :first, :find_one
      alias_method :each, :find_each
    end

    def find_one(opts={})
      query = clone.amend(opts)

      if identity_map && query.simple? && (document = identity_map.get_from_identity_map(query[:_id]))
        document
      else
        super.tap do |doc|
          doc.remove_from_identity_map if doc && query.fields?
        end
      end
    end

    def find_each(opts={})
      return super if !block_given?

      query = clone.amend(opts)
      super(opts) do |doc|
        doc.remove_from_identity_map if doc && query.fields?
        yield doc
      end
    end
  end
end

::MongoMapper::Plugins::Querying::DecoratedPluckyQuery.send :include, ::PluckyMethods::ClassMethods
