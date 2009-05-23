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
  end
end