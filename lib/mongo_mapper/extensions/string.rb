# encoding: UTF-8
module MongoMapper
  module Extensions
    module String
      extend ActiveSupport::Concern

      module ClassMethods
        def to_mongo(value)
          value && value.to_s
        end

        def from_mongo(value)
          value && value.to_s
        end
      end

      def _mongo_mapper_deep_copy_
        self.dup
      end
    end
  end
end

class String
  include MongoMapper::Extensions::String
end
