# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneAssociation < BelongsToAssociation
        def embeddable?
          klass.embeddable?
        end

        def proxy_class
          @proxy_class ||= klass.embeddable? ? OneEmbeddedProxy : OneProxy
        end

        def setup(model)
          super(model)

          model.class_eval <<-end_eval
            def build_#{name}(attrs={})
              get_proxy(associations[#{name.inspect}]).build(attrs)
            end

            def create_#{name}(attrs={})
              get_proxy(associations[#{name.inspect}]).create(attrs)
            end

            def create_#{name}!(attrs={})
              get_proxy(associations[#{name.inspect}]).create!(attrs)
            end
          end_eval
        end

      end
    end
  end
end