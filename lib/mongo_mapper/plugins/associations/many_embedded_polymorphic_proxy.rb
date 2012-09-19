# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyEmbeddedPolymorphicProxy < EmbeddedCollection
        def load_from_database(values)
          @_from_db = true
          @_values = values.map do |v|
            v.respond_to?(:attributes) ? v.attributes.merge(association.type_key_name => v.class.name) : v
          end
          reset
        end

        def replace(values)
          @_from_db = false
          @_values = values.map do |v|
            v.respond_to?(:attributes) ? v.attributes.merge(association.type_key_name => v.class.name) : v
          end
          reset
        end

        protected
          def find_target
            if !@_from_db
              (@_values || []).map do |hash|
                child = polymorphic_class(hash).new(hash)
                assign_references(child)
                child
              end
            else
              @_from_db = false
              (@_values || []).map do |hash|
                child = polymorphic_class(hash).load(hash)
                assign_references(child)
                child
              end
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
