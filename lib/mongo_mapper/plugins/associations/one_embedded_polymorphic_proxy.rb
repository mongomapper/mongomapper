# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneEmbeddedPolymorphicProxy < OneEmbeddedProxy
        def replace(value)
          @value = value.respond_to?(:attributes) ? value.attributes.merge(association.type_key_name => value.class.name) : value
          reset
        end
        
        protected
          def find_target
            if @value
              child = polymorphic_class(@value).load(@value)
              assign_references(child)
              child
            end
          end

          def polymorphic_class(doc)
            if class_name = doc[association.type_key_name]
              class_name.constantize
            else
              klass
            end
          end
      end
    end
  end
end