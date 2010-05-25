# encoding: UTF-8
module MongoMapper
  module Plugins
    module Equality
      module InstanceMethods
        def eql?(other)
          other.is_a?(self.class) && _id == other._id
        end
        alias :== :eql?

        def hash
          _id.hash
        end
      end
    end
  end
end