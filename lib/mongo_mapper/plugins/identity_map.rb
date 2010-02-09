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

        def find_one(options={})
          criteria, query_options = to_query(options)

          if simple_find?(criteria) && identity_map.key?(criteria[:_id])
            identity_map[criteria[:_id]]
          else
            super.tap do |document|
              remove_documents_from_map(document) if selecting_fields?(query_options)
            end
          end
        end

        def find_many(options)
          criteria, query_options = to_query(options)
          super.tap do |documents|
            remove_documents_from_map(documents) if selecting_fields?(query_options)
          end
        end

        def load(attrs)
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
          def remove_documents_from_map(*documents)
            documents.flatten.compact.each do |document|
              identity_map.delete(document._id)
            end
          end

          def simple_find?(criteria)
            criteria.keys == [:_id] || criteria.keys.to_set == [:_id, :_type].to_set
          end

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