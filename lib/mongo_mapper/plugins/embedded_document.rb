module MongoMapper
  module Plugins
    module EmbeddedDocument
      def self.configure(model)
        model.class_eval do
          attr_reader :_root_document, :_parent_document
        end
      end
      
      module ClassMethods
        def embeddable?
          true
        end

        def embedded_in(owner_name)
          define_method(owner_name) { _parent_document }
        end
      end

      module InstanceMethods
        def new?
          _root_document.try(:new?) || @new
        end

        def destroyed?
          !!_root_document.try(:destroyed?)
        end

        def save(options={})
          _root_document.try(:save, options).tap do |result|
            @new = false if result
          end
        end

        def save!(options={})
          _root_document.try(:save, options).tap do |result|
            @new = false if result
          end
        end

        def _parent_document=(value)
          @_root_document   = value._root_document
          @_parent_document = value
        end
      end
    end
  end
end