module MongoMapper
  module Validations    
    module Macros
      def validates_uniqueness_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesUniquenessOf)
      end
    end
    
    class ValidatesUniquenessOf < Validatable::ValidationBase
      option :scope
      
      def valid?(instance)
        value = instance[attribute]
        return true if allow_blank && value.blank?
        doc = instance.class.first({self.attribute => value}.merge(scope_conditions(instance)))
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
  end
end
