# encoding: UTF-8
module MongoMapper
  module Extensions
    module Hash
      def from_mongo(value)
        HashWithIndifferentAccess.new(value || {})
      end
    end
  end
end

class Hash
  extend MongoMapper::Extensions::Hash
end