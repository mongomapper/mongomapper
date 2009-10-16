module MongoMapper
  module RailsCompatibility
    module EmbeddedDocument
      def self.included(model)
        model.class_eval do
          extend ClassMethods
          
          alias_method :new_record?, :new?
        end

        class << model
          alias has_many many
        end
      end

      module ClassMethods
        def column_names
          keys.keys
        end
      end
    end
  end
end