module MongoMapper
  module RailsCompatibility
    module EmbeddedDocument
      def self.included(model)
        model.class_eval do
          extend ClassMethods
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

      def to_param
        raise "Missing to_param method in #{self.class}. You should implement it to return the unique identifier of this embedded document within a document."
      end
    end
  end
end