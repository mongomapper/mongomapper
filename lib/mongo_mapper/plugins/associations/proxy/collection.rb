# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class Collection < Proxy
        include Enumerable

        def to_a
          load_target

          target.is_a?(Array) ?
            target :
            Array(target)
        end

        alias_method :to_ary, :to_a

        def each(&block)
          to_a.each(&block)
        end

        def [](val)
          objs = to_a
          objs ? objs[val] : nil
        end

        def empty?
          to_a.empty?
        end

        def size
          to_a.size
        end

        def length
          to_a.length
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
