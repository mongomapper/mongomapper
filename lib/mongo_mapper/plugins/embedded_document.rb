# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedDocument
      def self.configure(model)
        model.class_eval do
          attr_accessor :_parent_document
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
          _root_document.try(:new?) || @_new
        end

        def destroyed?
          !!_root_document.try(:destroyed?)
        end

        def save(options={})
          _root_document.try(:save, options).tap do |result|
            @_new = false if result
          end
        end

        def save!(options={})
          _root_document.try(:save, options).tap do |result|
            @_new = false if result
          end
        end

        def _root_document
          @_root_document ||= _parent_document.try(:_root_document)
        end
      end
    end
  end
end