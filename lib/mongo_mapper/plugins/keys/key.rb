# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        attr_accessor :name, :type, :options, :default, :ivar, :abbr, :accessors

        ID_STR = '_id'

        def initialize(*args)
          options_from_args = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options_from_args || {}).symbolize_keys
          @dynamic     = !!options[:__dynamic]
          @embeddable  = type.respond_to?(:embeddable?) ? type.embeddable? : false
          @is_id       = @name == ID_STR
          @typecast    = @options[:typecast]
          @accessors   = Array(@options[:accessors]).compact.map &:to_s
          @has_default  = !!options.key?(:default)
          self.default = self.options[:default] if default?

          if abbr = @options[:abbr] || @options[:alias] || @options[:field_name]
            @abbr = abbr.to_s
          elsif @name.match(/^[A-Z]/) and !dynamic?
            @abbr = @name
            @name = @name.gsub(/^([A-Z])/) {|m| m.downcase }
            Kernel.warn "Key names may not start with uppercase letters. If your field starts " +
                 "with an uppercase letter, use :field_name to specify the real field name. " +
                 "Accessors called `#{@name}` have been created instead."
          end
          @ivar = :"@#{name}" if valid_ruby_name?
          validate_key_name! unless dynamic? or !any_accessor?
        end

        def persisted_name
          @abbr || @name
        end

        def ==(other)
          @name == other.name && @type == other.type && @abbr == other.abbr
        end

        def embeddable?
          @embeddable
        end

        def number?
          type == Integer || type == Float
        end

        def default?
          @has_default
        end

        def dynamic?
          @dynamic
        end

        def get(value)
          # Special Case: Generate default _id on access
          value = default_value if @is_id and !value

          if @typecast
            klass = typecast_class  # Don't make this lookup on every call
            type.from_mongo(value).map! { |v| klass.from_mongo(v) }
          else
            type.from_mongo(value)
          end
        end

        def set(value)
          # Avoid tap here so we don't have to create a block binding.
          values = type.to_mongo(value)
          values.map! { |v| typecast_class.to_mongo(v) } if @typecast
          values
        end

        def default_value
          return unless default?
          if default.instance_of? Proc
            type.to_mongo default.call
          else
            # Using Marshal is easiest way to get a copy of mutable objects
            # without getting an error on immutable objects
            type.to_mongo Marshal.load(Marshal.dump(default))
          end
        end

        def valid_ruby_name?
          !!@name.match(/\A[a-z_][a-z0-9_]*\z/i)
        end

        def read_accessor?
          any_accessor? ["read"]
        end

        def write_accessor?
          any_accessor? ["write"]
        end

        def predicate_accessor?
          any_accessor? ["present", "predicate", "boolean"]
        end

        def any_accessor?(arr_opt = [])
          return true if @accessors.empty?
          return false unless (@accessors & ["skip", "none"]).empty?
          return !(@accessors & arr_opt).empty?
        end

        private
          def typecast_class
            @typecast_class ||= options[:typecast].constantize
          end

          def validate_key_name!
            if %w( id ).include? @name
              raise MongoMapper::InvalidKey.new("`#{@name}` is a reserved key name (did you mean to use _id?)")
            elsif !valid_ruby_name?
              raise MongoMapper::InvalidKey.new("`#{@name}` is not a valid key name. Keys must match [a-z][a-z0-9_]*")
            end
          end
      end
    end
  end
end
