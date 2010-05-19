# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        attr_accessor :name, :type, :options, :default_value

        def initialize(*args)
          options = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options || {}).symbolize_keys
          self.default_value = self.options.delete(:default)
        end

        def ==(other)
          @name == other.name && @type == other.type
        end

        def embeddable?
          type.respond_to?(:embeddable?) && type.embeddable? ? true : false
        end

        def number?
          [Integer, Float].include?(type)
        end

        def get(value)
          if value.nil? && !default_value.nil?
            if default_value.respond_to?(:call)
              return default_value.call
            else
              return default_value
            end
          end

          type.from_mongo(value)
        end

        def set(value)
          type.to_mongo(value)
        end
      end
    end
  end
end