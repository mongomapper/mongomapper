module MongoMapper
  module Validations
    class ValidatesUniquenessOf < Validatable::ValidationBase
      def valid?(instance)
        # TODO: scope
        doc = instance.class.find(:first, :conditions => {self.attribute => instance[attribute]}, :limit => 1)
        doc.nil? || instance.id == doc.id
      end

      def message(instance)
        super || "has already been taken"
      end
    end
    
    class ValidatesExclusionOf < Validatable::ValidationBase
      required_option :within
      
      def valid?(instance)
        value = instance[attribute]
        return true if allow_nil && value.nil?
        return true if allow_blank && value.blank?
        
        !within.include?(instance[attribute])
      end
      
      def message(instance)
        super || "is reserved"
      end
    end

    class ValidatesInclusionOf < Validatable::ValidationBase
      required_option :within
      
      def valid?(instance)
        value = instance[attribute]
        return true if allow_nil && value.nil?
        return true if allow_blank && value.blank?
        
        within.include?(value)
      end
      
      def message(instance)
        super || "is not in the list"
      end
    end
  end
end
