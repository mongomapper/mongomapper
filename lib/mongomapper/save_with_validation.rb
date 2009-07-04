module MongoMapper
  module SaveWithValidation
    def self.included(base)
      base.class_eval do
        alias_method_chain :valid?, :callbacks
        alias_method_chain :save, :validation
        
        define_callbacks  :before_validation_on_create,   :before_validation_on_update,
                          :before_validation,             :after_validation,
                          :validate, :validate_on_create, :validate_on_update
      end
    end
    
    def save!
      save_with_validation || raise(DocumentNotValid.new(self))
    end
    
    private
      def save_with_validation        
        if valid?
          save_without_validation
        else
          false
        end
      end
    
      def valid_with_callbacks?
        run_callbacks(:before_validation)
        
        if new?
          run_callbacks(:before_validation_on_create)
        else
          run_callbacks(:before_validation_on_update)
        end
        
        run_callbacks(:validate)
        
        if new?
          run_callbacks(:validate_on_create)
        else
          run_callbacks(:validate_on_update)
        end
        
        is_valid = valid_without_callbacks?
        run_callbacks(:after_validation) if is_valid
        is_valid 
      end
  end  
end