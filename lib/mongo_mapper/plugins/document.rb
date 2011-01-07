# encoding: UTF-8
module MongoMapper
  module Plugins
    module Document
      module ClassMethods
        def embeddable?
          false
        end
      end

      module InstanceMethods
        def new?
          @_new
        end

        def destroyed?
          @_destroyed == true
        end

        def reload
          if doc = collection.find_one(:_id => id)
            tap do |instance|
              instance.class.associations.each_key do |association_name|
                if self.respond_to?(association_name) && !self.send(association_name).nil?
                  self.send(association_name).reset
                end
              end
              instance.attributes = doc
            end
          else
            raise DocumentNotFound, "Document match #{_id.inspect} does not exist in #{collection.name} collection"
          end
        end

        # Used by embedded docs to find root easily without if/respond_to? stuff.
        # Documents are always root documents.
        def _root_document
          self
        end
      end
    end
  end
end