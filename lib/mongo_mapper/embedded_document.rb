module MongoMapper
  module EmbeddedDocument
    extend Support::DescendantAppends

    def self.included(model)
      model.class_eval do
        include InstanceMethods
        extend  ClassMethods
        extend  Plugins

        plugin Plugins::Associations
        plugin Plugins::Clone
        plugin Plugins::Descendants
        plugin Plugins::Equality
        plugin Plugins::Inspect
        plugin Plugins::Keys
        plugin Plugins::Logger
        plugin Plugins::Protected
        plugin Plugins::Rails
        plugin Plugins::Serialization
        plugin Plugins::Validations
        plugin Plugins::Callbacks

        attr_reader :_root_document, :_parent_document
      end

      super
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
      def destroyed?
        _root_document.destroyed?
      end
      
      def save(options={})
        if result = _root_document.try(:save, options)
          @new = false
        end
        result
      end

      def save!(options={})
        if result = _root_document.try(:save!, options)
          @new = false
        end
        result
      end
      
      def _parent_document=(value)
        @_root_document   = value._root_document
        @_parent_document = value
      end
    end # InstanceMethods
  end # EmbeddedDocument
end # MongoMapper
