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
        ensure_root_document

        _root_document.try(:save, options).tap do |result|
          persist(options) if result
        end
      end

      def save!(options={})
        ensure_root_document

        valid? || raise(DocumentNotValid.new(self))
        _root_document.try(:save!, options).tap do |result|
          persist(options) if result
        end
      end

      def persist(options={})
        @_new = false
        changes_applied if respond_to?(:changes_applied)
        save_to_collection(options)
      end

      def _root_document
        _parent_document.try(:_root_document)
      end

      private

      def ensure_root_document
        raise NoRootDocument.new(self.class.name) unless _root_document
      end
    end
  end
end
