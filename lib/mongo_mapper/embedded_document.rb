module MongoMapper
  module EmbeddedDocument
    extend DescendantAppends
    
    def self.included(model)
      model.class_eval do
        include InstanceMethods
        extend  ClassMethods
        
        extend Plugins
        plugin Plugins::Associations
        plugin Plugins::Clone
        plugin Plugins::Descendants
        plugin Plugins::Equality
        plugin Plugins::Inspect
        plugin Plugins::Keys
        plugin Plugins::Logger
        plugin Plugins::Rails
        plugin Plugins::Serialization
        plugin Plugins::Validations

        attr_accessor :_root_document
      end
      
      super
    end

    module ClassMethods
      def embeddable?
        true
      end
    end

    module InstanceMethods
      def save(options={})
        _root_document.try(:save, options)
      end
      
      def save!(options={})
        _root_document.try(:save!, options)
      end

      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end

      def update_attributes!(attrs={})
        self.attributes = attrs
        save!
      end
    end # InstanceMethods
  end # EmbeddedDocument
end # MongoMapper
