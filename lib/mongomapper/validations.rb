module MongoMapper
  module Validations
    class ValidatesUniquenessOf < Validatable::ValidationBase
      option :scope
      
      def valid?(instance)
        doc = instance.class.find(:first, :conditions => {self.attribute => instance[attribute]}.merge(scope_conditions(instance)), :limit => 1)
        doc.nil? || instance.id == doc.id
      end

      def message(instance)
        super || "has already been taken"
      end
      
      def scope_conditions(instance)
        return {} unless scope
        Array(scope).inject({}) do |conditions, key|
          conditions.merge(key => instance[key])
        end
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
