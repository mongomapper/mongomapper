class Boolean; end
class Ref; end

module MongoMapper
  class Key
    # DateTime and Date are currently not supported by mongo's bson so just use Time
    NativeTypes = [String, Float, Time, Integer, Boolean, Array, Hash, Ref]

    attr_accessor :name, :type, :options, :default_value

    def initialize(name, type, options={})
      @name, @type = name.to_s, type
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
      @native ||= NativeTypes.include?(type)
    end

    def embedded_document?
      type.ancestors.include?(EmbeddedDocument) && !type.ancestors.include?(Document)
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
        return HashWithIndifferentAccess.new(value) if value.is_a?(Hash) && type == Hash
        return value if value.kind_of?(type) || value.nil?
        begin
          if    type == String    then value.to_s
          elsif type == Float     then value.to_f
          elsif type == Array     then value.to_a
          elsif type == Time      then Time.parse(value.to_s)
          #elsif type == Date      then Date.parse(value.to_s)
          elsif type == Boolean   then ['true', 't', '1'].include?(value.to_s.downcase)
          elsif type == Integer
            # ganked from datamapper
            value_to_i = value.to_i
            if value_to_i == 0 && value != '0'
              value_to_s = value.to_s
              begin
                Integer(value_to_s =~ /^(\d+)/ ? $1 : value_to_s)
              rescue ArgumentError
                nil
              end
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