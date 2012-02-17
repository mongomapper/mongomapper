# encoding: UTF-8
module MongoMapper
  module Extensions
    module Object
      extend ActiveSupport::Concern

      module ClassMethods
        def to_mongo(value)
          value
        end

        def from_mongo(value)
          value
        end
      end

      def to_mongo
        self.class.to_mongo(self)
      end
    end
  end
end

class Object
  include MongoMapper::Extensions::Object
end