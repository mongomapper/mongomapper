module MongoMapper
  module Validations
    class ValidatesUniquenessOf < Validatable::ValidationBase
      def valid?(instance)
        # TODO: scope
        s = instance.class.find(:first, :conditions => {self.attribute => instance[attribute]}, :limit => 1)
        s.nil? || instance.id == s.id
      end

      def message(instance)
        super || "is not unique"
      end
    end
  end
end
