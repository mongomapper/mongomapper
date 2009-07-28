module MongoMapper
  module RailsCompatibility
    module Document
      def self.included(model)
        model.class_eval do
          alias_method :new_record?, :new?
        end
      end

      def to_param
        id
      end
    end
  end
end