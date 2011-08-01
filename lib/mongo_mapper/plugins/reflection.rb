# encoding: UTF-8
module MongoMapper
  module Plugins
    
    module Reflection
      extend ActiveSupport::Concern

      module ClassMethods
        def reflect_on_association(assoc)
          associations[assoc].present? ? associations[assoc] : nil
        end        
      end
      
      module InstanceMethods
        def reflect_on_association(assoc)
          self.class.reflect_on_association(assoc)
        end
      end 
           
    end
    
  end
end