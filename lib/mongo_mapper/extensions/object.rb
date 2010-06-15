# encoding: UTF-8
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
      end
    end
  end
end

class Object
  extend MongoMapper::Extensions::Object::ClassMethods
  include MongoMapper::Extensions::Object::InstanceMethods
end