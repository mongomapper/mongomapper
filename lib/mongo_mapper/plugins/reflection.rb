# encoding: UTF-8
module MongoMapper
  module Plugins
    
    module Reflection
      extend ActiveSupport::Concern
      
      class Metadata
        attr_accessor :association
        
        def initialize(assoc)
          self.association = assoc
        end 
        
        [:as, :macro, :foreign_key, :embeddable?, :polymorphic?].each do |del|
          define_method(del) do
            association.try(del)
          end
        end
        alias :embedded? :embeddable?
        alias :name :as
        
        def class_name
          association.try(:klass).try(:name)
        end
                
        def inspect
          [:class_name, :embedded?, :macro, :foreign_key, :name, :polymorphic?].inject({}) do |hash, meth|
            hash.merge!(meth => send(meth))
          end
        end
               
      end
      
      module ClassMethods
        def reflect_on_association(assoc)
          Metadata.new(associations[assoc])
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