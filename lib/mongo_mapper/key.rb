class Boolean; end

module MongoMapper
  class Key
    NativeTypes = [String, Float, Time, Date, DateTime, Integer, Boolean]
    
    attr_accessor :name, :type
    
    def initialize(name, type)
      @name, @type = name.to_s, type
    end
    
    def ==(other)
      @name == other.name && @type == other.type
    end
    
    def set(value)
      typecast(value)
    end
    
    def get(value)
      value
    end
    
    private
      def typecast(value)
        return value if value.kind_of?(type) || value.nil?
        begin        
          if    type == String    then value.to_s
          elsif type == Float     then value.to_f
          elsif type == Time      then Time.parse(value.to_s)
          elsif type == Date      then Date.parse(value.to_s)
          elsif type == DateTime  then DateTime.parse(value.to_s)
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
          else
            value
          end
        rescue
          value
        end
      end
  end
end