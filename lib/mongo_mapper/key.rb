module MongoMapper
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

    def set(value)
      type.to_mongo(value)
    end

    def embeddable?
      type.respond_to?(:embeddable?) && type.embeddable? ? true : false
    end
    
    def number?
      [Integer, Float].include?(type)
    end

    def get(value)
      if value.nil? && !default_value.nil?
        return default_value
      end
      
      type.from_mongo(value)
    end
  end
end
