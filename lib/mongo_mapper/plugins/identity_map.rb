# encoding: UTF-8
require 'set'

module MongoMapper
  module Plugins
    module IdentityMap
      def self.models
        @models ||= Set.new
      end

      def self.clear
        models.each { |m| m.identity_map.clear }
      end

      def self.configure(model)
        IdentityMap.models << model
      end

      module ClassMethods
        def inherited(descendant)
          descendant.identity_map = identity_map
          super
        end

        def identity_map
          @identity_map ||= {}
        end

        def identity_map=(v)
          @identity_map = v
        end

        module IdentityMapQueryMethods
          def all(opts={})
            query = clone.update(opts)
            super.tap do |docs|
              model.remove_documents_from_map(docs) if query.fields?
            end
          end

          def find_one(opts={})
            query = clone.update(opts)

            if model.identity_map_on? && query.simple? && model.identity_map[query[:_id]]
              model.identity_map[query[:_id]]
            else
              super.tap do |doc|
                model.remove_documents_from_map(doc) if query.fields?
              end
            end
          end
        end

        def query(opts={})
          super.extend(IdentityMapQueryMethods)
        end

        def remove_documents_from_map(*documents)
          documents.flatten.compact.each do |document|
            identity_map.delete(document['_id'])
          end
        end

        def load(attrs)
          return nil if attrs.nil?
          document = identity_map[attrs['_id']]

          if document.nil? || identity_map_off?
            document = super
            identity_map[document._id] = document if identity_map_on?
          end

          document
        end

        def identity_map_status
          defined?(@identity_map_status) ? @identity_map_status : true
        end

        def identity_map_on
          @identity_map_status = true
        end

        def identity_map_off
          @identity_map_status = false
        end

        def identity_map_on?
          identity_map_status
        end

        def identity_map_off?
          !identity_map_on?
        end

        def without_identity_map(&block)
          identity_map_off
          yield
        ensure
          identity_map_on
        end

        private
          def selecting_fields?(options)
            !options[:fields].nil?
          end
      end

      module InstanceMethods
        def identity_map
          self.class.identity_map
        end

        def save(*args)
          if result = super
            identity_map[_id] = self if self.class.identity_map_on?
          end
          result
        end

        def delete
          identity_map.delete(_id) if self.class.identity_map_on?
          super
        end
      end
    end
  end
end