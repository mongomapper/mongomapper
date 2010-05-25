module MongoMapper
  module Extensions
    module Object
      module ClassMethods
        def to_mongo(value)
          value
        end

        def from_mongo(value)
          value
        end
      end

      module InstanceMethods
        def to_mongo
          self.class.to_mongo(self)
        end

        # The hidden singleton lurks behind everyone
        def metaclass
          class << self; self end
        end

        def meta_eval(&blk)
          metaclass.instance_eval(&blk)
        end

        # Adds methods to a metaclass
        def meta_def(name, &blk)
          meta_eval { define_method(name, &blk) }
        end

        # Defines an instance method within a class
        def class_def(name, &blk)
          class_eval { define_method(name, &blk) }
        end
      end
    end
  end
end

class Object
  extend MongoMapper::Extensions::Object::ClassMethods
  include MongoMapper::Extensions::Object::InstanceMethods
end