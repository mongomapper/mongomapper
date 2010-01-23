module MongoMapper
  module Plugins
    module IdentityMap
      def self.models
        @models ||= Set.new
      end
      
      def self.clear
        models.each { |m| m.identity_map.clear }
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
          criteria, finder_options   = to_finder_options(options)
          document_in_map            = identity_map[criteria[:_id]]
          find_by_single_id          = criteria.keys == [:_id]
          find_by_single_id_with_sci = criteria.keys.to_set == [:_id, :_type].to_set

          if find_by_single_id && document_in_map
            document_in_map
          elsif find_by_single_id_with_sci && document_in_map
            document_in_map
          else
            super.tap do |document|
              remove_documents_from_map(document) unless finder_options[:fields].nil?
            end
          end
        end

        def find_many(options)
          criteria, finder_options = to_finder_options(options)
          super.tap do |documents|
            remove_documents_from_map(documents) unless finder_options[:fields].nil?
          end
        end

        def load(attrs)
          unless document = identity_map[attrs['_id']]
            document = super
            identity_map[document._id] = document
          end

          document
        end
        
        private
          def remove_documents_from_map(*documents)
            documents.flatten.compact.each do |document|
              identity_map.delete(document._id)
            end
          end
      end

      module InstanceMethods
        def self.included(model)
          IdentityMap.models << model
        end

        def identity_map
          self.class.identity_map
        end

        def save(*args)
          if result = super
            identity_map[_id] = self
          end
          result
        end

        def delete
          identity_map.delete(_id)
          super
        end
      end
    end
  end
end