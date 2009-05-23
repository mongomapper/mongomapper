module MongoMapper
  module Document
    def self.included(model)
      model.extend ClassMethods
      model.extend Forwardable
      model.instance_eval do
        def_delegators :keys, :[], :[]=
      end
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
    
    def initialize(k={})
      self.keys = k
    end
    
    def keys=(new_keys)
      @keys = keys.merge(only_defined_keys(new_keys))
    end
    
    def keys
      @keys || HashWithIndifferentAccess.new
    end
    
    def method_missing(method, *args, &block)
      defined_keys = defined_keys()
      key = method.to_s
      
      if defined_keys.include?(key)
        return attribute_get(key)
      elsif key =~ /=$/ && defined_keys.include?(key.chop)
        return attribute_set(key.chop, args[0])
      else
        raise NoMethodError, "#{method} is not defined as a key for #{self}"
      end
    end
    
    private
      def attribute_get(name)
        defined_key(name).get(self[name])
      end
      
      def attribute_set(name, value)
        self[name] = defined_key(name).set(value)
      end
    
      def defined_key(name)
        self.class.keys[name]
      end
      
      def defined_keys
        self.class.keys.keys
      end
      
      def only_defined_keys(hash={})
        defined_keys = defined_keys()
        hash.delete_if { |k, v| !defined_keys.include?(k.to_s) }
      end
  end # Document
end # MongoMapper