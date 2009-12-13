module MongoMapper
  module Associations
    class ManyEmbeddedPolymorphicProxy < Collection
      def replace(values)
        @_values = values.map do |v|
          if v.kind_of?(EmbeddedDocument)
            v.attributes.merge(reflection.type_key_name => v.class.name)
          else
            v
          end
        end
        reset
      end

      protected
        def find_target
          (@_values || []).map do |hash|
            polymorphic_class(hash).new(hash)
          end
        end
        
        def polymorphic_class(doc)
          if class_name = doc[reflection.type_key_name]
            class_name.constantize
          else
            klass
          end
        end
    end
  end
end
