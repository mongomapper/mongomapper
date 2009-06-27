module MongoMapper
  module SaveWithValidation
    def self.included(base)
      base.class_eval do
        alias_method_chain :valid?, :callbacks
        alias_method_chain :save, :validation
      end
    end
    
    def save!
      save_with_validation || raise(DocumentNotValid.new(self))
    end
    
    private
      def save_with_validation
        new? ? run_callbacks(:before_validation_on_create) : 
               run_callbacks(:before_validation_on_update)
      
        valid? ? save_without_validation : false
      end
    
      def valid_with_callbacks?
        run_callbacks(:before_validation)
        run_callbacks(:after_validation) if valid_without_callbacks?
      end
  end  
end