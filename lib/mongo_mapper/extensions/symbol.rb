# encoding: UTF-8
module MongoMapper
  module Extensions
    module Symbol
      def to_mongo(value)
        value.to_s
      end

      def from_mongo(value)
        value.to_sym
      end
    end
  end
end

class Symbol
  extend MongoMapper::Extensions::Symbol
end
