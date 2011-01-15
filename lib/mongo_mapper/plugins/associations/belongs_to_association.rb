# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class BelongsToAssociation < Base

        def embeddable?
          false
        end

        def proxy_class
          @proxy_class ||= polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
        end

        def setup(model)

          model.class_eval <<-end_eval
            def #{name}
              proxy = get_proxy(associations[#{name.inspect}])
              proxy.nil? ? nil : proxy
            end

            def #{name}=(value)
              association = associations[#{name.inspect}]
              proxy = get_proxy(association)

              if proxy.nil? || proxy.target != value
                proxy = build_proxy(association)
              end

              proxy.replace(value)
              value
            end

            def #{name}?
              get_proxy(associations[#{name.inspect}]).present?
            end
          end_eval
        end
      end
    end
  end
end