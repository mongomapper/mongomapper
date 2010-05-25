# encoding: UTF-8
module MongoMapper
  module Extensions
    module String
      def to_mongo(value)
        value.nil? ? nil : value.to_s
      end

      def from_mongo(value)
        value.nil? ? nil : value.to_s
      end
    end
  end
end

class String
  extend MongoMapper::Extensions::String
end