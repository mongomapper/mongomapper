# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        attr_accessor :name, :type, :options, :default

        ID_STR = '_id'

        def initialize(*args)
          options_from_args = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options_from_args || {}).symbolize_keys

          if options.key?(:default)
            self.default = self.options[:default]
          end
        end

        def ==(other)
          @name == other.name && @type == other.type
        end

        def embeddable?
          # This is ugly, but it's fast. We can't use ||= because false is an expected and common value.
          @embeddable = @embeddable != nil ? @embeddable : begin
            if type.respond_to?(:embeddable?)
              type.embeddable?
            else
              false
            end
          end
        end

        def number?
          type == Integer || type == Float
        end

        def default?
          options.key?(:default)
        end

        def get(value)
          # Special Case: Generate default _id on access
          value = default_value if value.nil? and name == ID_STR

          if options[:typecast]
            type.from_mongo(value).map! { |v| typecast_class.from_mongo(v) }
          else
            type.from_mongo(value)
          end
        end

        def set(value)
          type.to_mongo(value).tap do |values|
            if options[:typecast]
              values.map! { |v| typecast_class.to_mongo(v) }
            end
          end
        end

        def default_value
          return unless default?

          if default.respond_to?(:call)
            default.call
          else
            # Using Marshal is easiest way to get a copy of mutable objects
            # without getting an error on immutable objects
            Marshal.load(Marshal.dump(default))
          end
        end

        private
          def typecast_class
            @typecast_class ||= options[:typecast].constantize
          end
      end
    end
  end
end
