module MongoMapper
  module RailsCompatibility
    def self.included(model)
      model.class_eval do
        alias_method :new_record?, :new?
        extend ClassMethods
      end
      class << model
        alias_method :has_many, :many
      end
    end

    module ClassMethods
      def column_names
        keys.keys
      end
    end

    def to_param
      id
    end
  end
end