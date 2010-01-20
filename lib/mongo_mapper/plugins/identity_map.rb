module MongoMapper
  module Plugins
    module IdentityMap
      def self.identity_map
        Thread.current[:mongo_mapper_identity_map] ||= {}
      end
      
      def self.identity_map=(v)
        Thread.current[:mongo_mapper_identity_map] = v
      end
      
      module ClassMethods
        def identity_map
          IdentityMap.identity_map
        end

        def identity_map=(v)
          IdentityMap.identity_map = v
        end

        def identity_map_key(id)
          "#{collection.name}:#{id}"
        end

        def find_one(options={})
          criteria, finder_options = to_finder_options(options)

          if criteria.keys == [:_id] && document = identity_map[identity_map_key(criteria[:_id])]
            document
          else
            document = super.tap do |document|
              remove_documents_from_map(document) unless finder_options[:fields].nil?
            end
          end

          document
        end

        def find_many(options)
          criteria, finder_options = to_finder_options(options)
          super.tap do |documents|
            remove_documents_from_map(documents) unless finder_options[:fields].nil?
          end
        end

        def load(attrs)
          key = identity_map_key(attrs['_id'])
          unless document = identity_map[key]
            document = super
            identity_map[document.identity_map_key] = document
          end

          document
        end
        
        private
          def remove_documents_from_map(*documents)
            documents.flatten.each do |document|
              identity_map.delete(identity_map_key(document._id))
            end
          end
      end

      module InstanceMethods
        def identity_map_key
          @identity_map_key ||= self.class.identity_map_key(_id)
        end

        def identity_map
          self.class.identity_map
        end

        def save(*args)
          if result = super
            identity_map[identity_map_key] = self
          end
          result
        end

        def delete
          identity_map.delete(identity_map_key)
          super
        end
      end
    end
  end
end