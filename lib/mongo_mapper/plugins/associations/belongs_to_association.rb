# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToAssociation < SingleAssociation
        def type_key_name
          "#{as}_type"
        end

        def embeddable?
          false
        end

        def proxy_class
          @proxy_class ||= polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
        end

        def setup(model)
          model.key foreign_key, ObjectId unless model.key?(foreign_key)
          super
          add_touch_callbacks if options.fetch(:touch, false)
        end

        def autosave?
          options.fetch(:autosave, false)
        end
        
        def add_touch_callbacks
          binding.pry
          
        end
      end
    end
  end
end