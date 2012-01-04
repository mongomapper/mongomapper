# encoding: UTF-8
module MongoMapper
  module Plugins
    module Document
      extend ActiveSupport::Concern

      module ClassMethods
        def embeddable?
          false
        end
      end

      def new?
        @_new
      end

      def destroyed?
        @_destroyed == true
      end

      def reload
        if doc = collection.find_one(:_id => id)
          self.class.associations.each_value do |association|
            get_proxy(association).reset
          end
          instance_variables.each { |ivar| instance_variable_set(ivar, nil) }
          load_from_database(doc)
          self
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