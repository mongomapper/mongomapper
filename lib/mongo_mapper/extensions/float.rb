# encoding: UTF-8
module MongoMapper
  module Extensions
    module Float
      def to_mongo(value)
        value.blank? ? nil : value.to_f
      end
    end
  end
end

class Float
  extend MongoMapper::Extensions::Float
end