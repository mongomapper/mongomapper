module MongoMapper
  module Validation
    def self.included(base)
      base.class_eval do
        alias_method_chain :valid?, :callbacks
        alias_method_chain :save, :validation
      end
    end
    
    def save_with_validation
      if new?
        run_callbacks(:before_validation_on_create)
      else
        run_callbacks(:before_validation_on_update)
      end
      if valid?
        save_without_validation
      else
        false
      end
    end
    private :save_with_validation
    
    def valid_with_callbacks?
      run_callbacks(:before_validation)
      run_callbacks(:after_validation) if valid_without_callbacks?
    end
    private :valid_with_callbacks?
  end
  
end