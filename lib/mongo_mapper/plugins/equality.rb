# encoding: UTF-8
module MongoMapper
  module Plugins
    module Equality
      extend ActiveSupport::Concern

      module ClassMethods
        def ===(other)
          other.is_a?(self)
        end
      end

      def eql?(other)
        other.is_a?(self.class) && _id == other._id
      end
      alias :== :eql?

      def hash
        _id.hash
      end
    end
  end
end
