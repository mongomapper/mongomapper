module MongoMapper
  module Document
    def self.included(model)
      model.extend ClassMethods
      model.extend Forwardable
    end
    
    module ClassMethods
      def key(name, type)
        key = Key.new(name, type)
        keys[key.name] = key
        key
      end
      
      def keys
        @keys ||= HashWithIndifferentAccess.new
      end
    end
    
    ####################
    # Instance Methods #
    ####################
    
    def initialize(attrs={})
      self.attributes = attrs
    end
    
    def attributes=(attrs)
      attrs.each_pair do |k, v|
        setter = "#{k}="
        send(setter, v) if writer?(k)
      end
    end
    
    def attributes
      self.class.keys.inject(HashWithIndifferentAccess.new) do |hash, key_hash|
        name, key = key_hash
        value = read_attribute(name)
        hash[name] = value unless value.nil?
        hash
      end
    end
    
    def reader?(name)
      defined_key_names.include?(name.to_s)
    end
    
    def writer?(name)
      name = name.chop if name =~ /=$/
      reader?(name)
    end
    
    def [](name)
      read_attribute(name)
    end
    
    def []=(name, value)
      write_attribute(name, value)
    end
    
    def method_missing(method, *args, &block)
      attribute = method.to_s
      
      if reader?(attribute)
        return read_attribute(attribute)
      elsif writer?(attribute)
        return write_attribute(attribute.chop, args[0])
      else
        super
      end
    end
    
    private
      def read_attribute(name)
        defined_key(name).get(instance_variable_get("@#{name}"))
      end
      
      def write_attribute(name, value)
        instance_variable_set "@#{name}", defined_key(name).set(value)
      end
    
      def defined_key(name)
        self.class.keys[name]
      end
      
      def defined_key_names
        self.class.keys.keys
      end
      
      def only_defined_keys(hash={})
        defined_key_names = defined_key_names()
        hash.delete_if { |k, v| !defined_key_names.include?(k.to_s) }
      end
  end # Document
end # MongoMapper