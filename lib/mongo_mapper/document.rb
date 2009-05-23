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
        keys << key
        key
      end
      
      def keys
        @keys ||= []
      end
    end
    
    ####################
    # Instance Methods #
    ####################
    
    def initialize(k={})
      self.keys = k
    end
    
    def keys=(new_keys)
      @keys = keys.merge(valid_keys(new_keys))
    end
    
    def keys
      @keys || HashWithIndifferentAccess.new
    end
    
    private
      def valid_keys(hash={})
        valid_keys = self.class.keys.map { |k| k.name.to_s }
        hash.delete_if { |k, v| !valid_keys.include?(k.to_s) }
      end
  end # Document
end # MongoMapper