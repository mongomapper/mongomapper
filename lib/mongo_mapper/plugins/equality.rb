module MongoMapper
  module Plugins
    module Equality
      module InstanceMethods
        def ==(other)
          other.is_a?(self.class) && _id == other._id
        end
        
        def eql?(other)
          self == other
        end
        
        def equal?(other)
          object_id === other.object_id
        end
        
        def hash
          _id.hash
        end
      end
    end
  end
end