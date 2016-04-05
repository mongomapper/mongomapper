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
        !!(@_new ||= false)
      end

      def destroyed?
        !!(@_destroyed ||= false)
      end

      def reload
        if doc = collection.find({:_id => id},{limit: -1}).first
          self.class.associations.each_value do |association|
            get_proxy(association).reset
          end
          instance_variables.each { |ivar| remove_instance_variable(ivar) }
          initialize_from_database(doc)
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