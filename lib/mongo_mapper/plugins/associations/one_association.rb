# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAssociation < SingleAssociation
        def embeddable?
          klass.embeddable?
        end

        def proxy_class
          @proxy_class ||=
            if klass.embeddable?
              polymorphic? ? OneEmbeddedPolymorphicProxy : OneEmbeddedProxy
            elsif as?
              OneAsProxy
            else
              OneProxy
            end
        end

        def setup(model)
          super

          association = self
          options = self.options

          model.before_destroy do
            if !association.embeddable?
              proxy = self.get_proxy(association)

              unless proxy.nil?
                case options[:dependent]
                  when :destroy then proxy.destroy
                  when :delete  then proxy.delete
                  else proxy.nullify
                end
              end
            end
          end
        end

        def autosave?
          options.fetch(:autosave, embeddable?)
        end
      end
    end
  end
end