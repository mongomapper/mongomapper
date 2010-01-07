module MongoMapper
  module Plugins
    def plugins
      @plugins ||= []
    end
    
    def plugin(mod)
      if mod.const_defined?(:ClassMethods)
        extend mod::ClassMethods
      end
      
      if mod.const_defined?(:InstanceMethods)
        include mod::InstanceMethods
      end
      
      plugins << mod
    end
  end
end