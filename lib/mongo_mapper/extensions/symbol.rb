# encoding: UTF-8
module MongoMapper
  module Extensions
    module Symbol
      def to_mongo(value)
        value && value.to_s.to_sym
      end

      def from_mongo(value)
        value && value.to_s.to_sym
      end
    end
  end
end

class Symbol
  extend MongoMapper::Extensions::Symbol

  # Symbol#name was added in Ruby 3.0. Remove when Ruby 2.x support is dropped.
  alias_method :name, :to_s unless method_defined?(:name)
end
