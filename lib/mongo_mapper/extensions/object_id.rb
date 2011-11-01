# encoding: UTF-8
module MongoMapper
  module Extensions
    module ObjectId
      def to_mongo(value)
        Plucky.to_object_id(value)
      end

      def from_mongo(value)
        value
      end
    end
  end
end

class ObjectId
  extend MongoMapper::Extensions::ObjectId
end

class BSON::ObjectId
  alias_method :original_to_json, :to_json

  def as_json(options=nil)
    to_s
  end

  def to_json(options = nil)
    as_json.to_json
  end

  alias to_str to_s
end