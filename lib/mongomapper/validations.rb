module MongoMapper
  module Validations    
    module Macros
      def validates_uniqueness_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesUniquenessOf)
      end

      def validates_exclusion_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesExclusionOf)
      end

      def validates_inclusion_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesInclusionOf)
      end
    end
    
    class ValidatesUniquenessOf < Validatable::ValidationBase
      option :scope

      def valid?(instance)
        conditions = {self.attribute => instance[attribute]}
        if scope
          conditions.merge!(scope => instance[scope])
        end
        doc = instance.class.find(:first, :conditions => conditions, :limit => 1)
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
