module MongoMapper
  module Validation
    def self.included(base)
      base.class_eval do
        extend ClassMethods
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
  
  module ClassMethods
    def apply_validations(key)
      attribute = key.name.to_sym
      
      if key.options[:required]
        validates_presence_of(attribute)
      end
      
      if key.options[:numeric]
        number_options = key.type == Integer ? {:only_integer => true} : {}
        validates_numericality_of(attribute, number_options)
      end
      
      if key.options[:format]
        validates_format_of(attribute, :with => key.options[:format])
      end
      
      if key.options[:length]
        length_options = case key.options[:length]
        when Integer
          {:minimum => 0, :maximum => key.options[:length]}
        when Range
          {:within => key.options[:length]}
        when Hash
          key.options[:length]
        end
        
        validates_length_of(attribute, length_options)
      end
    end
    private :apply_validations
  end
end