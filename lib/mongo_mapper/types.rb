module MongoMapper
  module Types
    class Binary
      def self.to_mongo(value)
        if value.is_a?(ByteBuffer)
          value
        else
          value.nil? ? nil : ByteBuffer.new(value)
        end
      end

      def self.from_mongo(value)
        value
      end
    end
    
    class Boolean
      def self.to_mongo(value)
        if value.is_a?(Boolean)
          value
        else
          ['true', 't', '1'].include?(value.to_s.downcase)
        end
      end

      def self.from_mongo(value)
        !!value
      end
    end
    
    class ObjectId
      def self.to_mongo(value)
        if value.nil?
          nil
        elsif value.is_a?(Mongo::ObjectID)
          value
        else
          Mongo::ObjectID.from_string(value.to_s)
        end
      end
      
      def self.from_mongo(value)
        value
      end
    end
    
    # This allows using just Boolean when defining 
    # keys instead of MongoMapper::Types::Boolean
    module Lookup
      def const_missing(name)
        if MongoMapper::Types.const_defined?(name)
          MongoMapper::Types.const_get(name)
        else
          super
        end
      end
    end
  end
end

# This was required to get in front of ActiveSupports Class#const_missing
Class.instance_eval do
  include MongoMapper::Types::Lookup
end
