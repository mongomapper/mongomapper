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

        def reset
          super
          target = []
        end
      end
    end
  end
end