module MongoMapper
  module SaveWithValidation
    def self.included(base)
      base.class_eval do
        alias_method_chain :save, :validation
        alias_method_chain :save!, :validation
      end
    end
    
    private
      def save_with_validation
        valid? ? save_without_validation : false
      end
      
      def save_with_validation!
        valid? ? save_without_validation! : raise(DocumentNotValid.new(self))
      end
  end  
end