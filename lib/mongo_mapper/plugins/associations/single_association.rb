# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class SingleAssociation < Base
        def setup(model)
          @model = model

          model.associations_module.module_eval(<<-end_eval, __FILE__, __LINE__ + 1)
            def #{name}
              get_proxy(associations[#{name.inspect}]).read
            end

            def #{name}=(value)
              get_proxy(associations[#{name.inspect}]).write(value)
            end

            def #{name}?
              get_proxy(associations[#{name.inspect}]).present?
            end

            def build_#{name}(attrs={}, &block)
              get_proxy(associations[#{name.inspect}]).build(attrs, &block)
            end

            def create_#{name}(attrs={}, &block)
              get_proxy(associations[#{name.inspect}]).create(attrs, &block)
            end

            def create_#{name}!(attrs={}, &block)
              get_proxy(associations[#{name.inspect}]).create!(attrs, &block)
            end
          end_eval
        end
      end
    end
  end
end
