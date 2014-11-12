# encoding: UTF-8
module MongoMapper
  module Extensions
    module Hash
      extend ActiveSupport::Concern

      module ClassMethods
        def from_mongo(value)
          HashWithIndifferentAccess.new(value || {})
        end
      end

      def _mongo_mapper_deep_copy_
        self.class.new.tap do |new_hash|
          each do |key, value|
            new_hash[key._mongo_mapper_deep_copy_] = value._mongo_mapper_deep_copy_
          end
        end
      end
    end
  end
end

class Hash
  include MongoMapper::Extensions::Hash
end