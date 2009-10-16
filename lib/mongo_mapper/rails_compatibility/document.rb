module MongoMapper
  module RailsCompatibility
    module Document
      def self.included(model)
        model.class_eval do
          alias_method :new_record?, :new?
        end
      end
    end
  end
end