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

        module IdentityMapQueryMethods
          def find_one(opts={})
            query = clone.amend(opts)

            if query.simple? && (document = model.get_from_identity_map(query[:_id]))
              document
            else
              super.tap do |doc|
                doc.remove_from_identity_map if doc && query.fields?
              end
            end
          end

          def find_each(opts={})
            query = clone.amend(opts)
            super(opts) do |doc|
              doc.remove_from_identity_map if doc && query.fields?
              yield doc if block_given?
            end
          end

          def first(opts={})
            find_one(opts)
          end

          def each(opts={})
            find_each(opts)
          end

        end

        def query(opts={})
          if IdentityMap.enabled?
            super.extend(IdentityMapQueryMethods)
          else
            super
          end
        end

        def remove_documents_from_map(*documents)
          documents.flatten.compact.each do |document|
            document.remove_from_identity_map
          end
        end

        def load(attrs)
          return nil if attrs.nil?
          document = get_from_identity_map(attrs['_id'])

          if document.nil?
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
