# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToAssociation < SingleAssociation
        def embeddable?
          false
        end

        def proxy_class
          @proxy_class ||= polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
        end

        def setup(model)
          model.key foreign_key, ObjectId unless model.key?(foreign_key)
          super
        end

        def autosave?
          options.fetch(:autosave, false)
        end
      end
    end
  end
end