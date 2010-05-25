# encoding: UTF-8
module MongoMapper
  module Extensions
    module NilClass
      def to_mongo(value)
        value
      end

      def from_mongo(value)
        value
      end
    end
  end
end

class NilClass
  include MongoMapper::Extensions::NilClass
end