module MongoMapper
  module Plugins
    module IdentityMap
      def self.models
        @models ||= Set.new
      end
      
      def self.clear
        models.each { |m| m.identity_map.clear }
      end

      def self.status
        defined?(@map) ? @map : true
      end

      def self.on
        @map = true
      end
      
      def self.off
        @map = false
      end
      
      def self.on?
        status
      end
      
      def self.off?
        !on?
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
          criteria, finder_options = to_finder_options(options)

          if simple_find?(criteria) && identity_map.key?(criteria[:_id])
            identity_map[criteria[:_id]]
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
          document = identity_map[attrs['_id']]
          
          if document.nil? || IdentityMap.off?
            document = super
            identity_map[document._id] = document if IdentityMap.on?
          end

          document
        end
        
        def without_identity_map(&block)
          IdentityMap.off
          yield
        ensure
          IdentityMap.on
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
            identity_map[_id] = self if IdentityMap.on?
          end
          result
        end

        def delete
          identity_map.delete(_id) if IdentityMap.on?
          super
        end
      end
    end
  end
end