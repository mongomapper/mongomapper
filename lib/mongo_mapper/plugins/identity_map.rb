module MongoMapper
  module Plugins
    module IdentityMap
      module ClassMethods
        def identity_map
          Thread.current[:mongo_mapper_identity_map] ||= {}
        end

        def identity_map=(v)
          Thread.current[:mongo_mapper_identity_map] = v
        end

        def identity_map_key(id)
          "#{self}:#{id}"
        end

        def find_one(options={})
          criteria, options = to_finder_options(options)
          key = identity_map_key(criteria[:_id])

          if document = identity_map[key]
            document
          else
            document = super
          end
          
          document
        end

        def load(attrs)
          id = attrs[:_id] || attrs[:id] || attrs['_id'] || attrs['id']
          key = identity_map_key(id)

          unless document = identity_map[key]
            document = super
            identity_map[document.identity_map_key] = document
          end

          document
        end
      end

      module InstanceMethods
        def identity_map_key
          @identity_map_key ||= self.class.identity_map_key(_id)
        end

        def identity_map
          self.class.identity_map
        end

        def save
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