# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class Collection < Proxy
        def to_ary
          load_target
          if target.is_a?(Array)
            target.to_ary
          else
            Array(target)
          end
        end

        alias_method :to_a, :to_ary

        def include?(*args)
          load_target
          target.include?(*args)
        end

        def reset
          super
          target = []
        end

        def read
          self
        end

        def write(value)
          replace(value)
          read
        end
      end
    end
  end
end
