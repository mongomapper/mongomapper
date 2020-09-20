# encoding: UTF-8
module MongoMapper
  module Extensions
    module Binary
      def to_mongo(value)
        if value.instance_of?(::BSON::Binary)
          value
        else
          value.nil? ? nil : ::BSON::Binary.new(value)
        end
      end

      def from_mongo(value)
        value
      end
    end
  end
end

class Binary
  extend MongoMapper::Extensions::Binary
end
