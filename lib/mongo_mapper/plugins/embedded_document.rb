# encoding: UTF-8
module MongoMapper
  module Plugins
    module EmbeddedDocument
      extend ActiveSupport::Concern

      included do
        attr_accessor :_parent_document
      end

      module ClassMethods
        def embeddable?
          true
        end

        def embedded_in(owner_name)
          alias_method owner_name, :_parent_document
        end
      end

      def new?
        _root_document.try(:new?) || @_new
      end

      def destroyed?
        !!_root_document.try(:destroyed?)
      end

      def save(options={})
        _root_document.try(:save, options).tap do |result|
          persist(options) if result
        end
      end

      def save!(options={})
        valid? || raise(DocumentNotValid.new(self))
        _root_document.try(:save!, options).tap do |result|
          persist(options) if result
        end
      end

      def persist(options={})
        @_new = false
        clear_changes if respond_to?(:clear_changes)
        save_to_collection(options)
      end

      def _root_document
        @_root_document ||= _parent_document.try(:_root_document)
      end
    end
  end
end
