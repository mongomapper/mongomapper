module MongoMapper
  class Key
    # DateTime and Date are currently not supported by mongo's bson so just use Time
    NativeTypes = [String, Float, Time, Date, Integer, Boolean, Array, Hash]

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
      if value.nil? && !default_value.nil?
        return default_value
      end
      
      if type == Array
        value || []
      elsif type == Hash
        HashWithIndifferentAccess.new(value || {})
      elsif type == Date && value.present?
        value.send(:to_date)
      elsif type == Time && value.present?
        if Time.respond_to?(:zone) && Time.zone
          value.in_time_zone(Time.zone)
        else
          value
        end
      elsif type.respond_to?(:from_mongo)
        type.from_mongo(value)
      else
        value
      end
    end

    def to_normalized_date(value)
      date = Date.parse(value.to_s)
      Time.utc(date.year, date.month, date.day)
    rescue
      nil
    end

    private
      def typecast(value)
        if type.nil?
          return value
        end
        
        if value.is_a?(Hash) && type == Hash
          return HashWithIndifferentAccess.new(value)
        end
        
        if type == Time && value.kind_of?(type)
          return to_utc_time(value)
        end
        
        if ((native? && value.kind_of?(type)) || value.nil?) && type != Array
          return value
        end
        
        begin
          if    type == String    then value.to_s
          elsif type == Float     then value.to_f
          elsif type == Array     then value.to_a
          elsif type == Time      then to_utc_time(value)
          elsif type == Date      then to_normalized_date(value)
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
          elsif type.respond_to?(:to_mongo)
            type.to_mongo(value)
          else
            value
          end
        rescue
          value
        end
      end
      
      def to_utc_time(value)
        to_local_time(value).utc
      end
      
      # make sure we have a time and that it is local
      def to_local_time(value)
        if Time.respond_to?(:zone) && Time.zone
          Time.zone.parse(value.to_s)
        else
          Time.parse(value.to_s)
        end
      end

      def typecast_embedded_document(value)
        value.is_a?(type) ? value : type.new(value)
      end
  end
end
