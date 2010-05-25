# encoding: UTF-8
module MongoMapper
  module Extensions
    module Array
      def to_mongo(value)
        value = value.respond_to?(:lines) ? value.lines : value
        value.to_a
      end

      def from_mongo(value)
        value || []
      end
    end
  end
end

class Array
  extend MongoMapper::Extensions::Array
end