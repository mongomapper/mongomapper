module MongoMapper
  module Plugins
    module Equality
      module InstanceMethods
        def ==(other)
          other.is_a?(self.class) && _id == other._id
        end
      end
    end
  end
end