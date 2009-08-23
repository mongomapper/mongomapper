module MongoMapper
  class Key
    # DateTime and Date are currently not supported by mongo's bson so just use Time
    NativeTypes = [String, Float, Time, Integer, Boolean, Array, Hash]

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

    def set(value)
      typecast(value)
    end

    def native?
      @native ||= NativeTypes.include?(type) || type.nil?
    end

    def embedded_document?
      type.respond_to?(:embeddable?) && type.embeddable?
    end

    def get(value)
      return default_value if value.nil? && !default_value.nil?
      if type == Array
        value || []
      elsif type == Hash
        HashWithIndifferentAccess.new(value || {})
      else
        value
      end
    end

    private
      def typecast(value)
        return value if type.nil?
        return HashWithIndifferentAccess.new(value) if value.is_a?(Hash) && type == Hash
        return value.utc if type == Time && value.kind_of?(type)
        return value if value.kind_of?(type) || value.nil?
        begin
          if    type == String    then value.to_s
          elsif type == Float     then value.to_f
          elsif type == Array     then value.to_a
          elsif type == Time      then Time.parse(value.to_s).utc
          elsif type == Boolean   then Boolean.mm_typecast(value)
          elsif type == Integer
            # ganked from datamapper
            value_to_i = value.to_i
            if value_to_i == 0
              value.to_s =~ /^(0x|0b)?0+/ ? 0 : nil
            else
              value_to_i
            end
          elsif embedded_document?
            typecast_embedded_document(value)
          else
            value
          end
        rescue
          value
        end
      end

      def typecast_embedded_document(value)
        value.is_a?(type) ? value : type.new(value)
      end
  end
end