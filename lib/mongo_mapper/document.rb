module MongoMapper
  module Document
    def self.included(model)
      model.extend ClassMethods
      model.extend Forwardable
      model.class_eval { key :_id, String }
    end
    
    module ClassMethods      
      def find(id)
        if doc = collection.find_first({:_id => id})
          return new(doc)
        else
          raise DocumentNotFound, "Document with id of #{id} does not exist in collection named #{collection.name}"
        end
      end
      
      def create(*docs)
        rows = []
        docs.flatten.each { |attrs| rows << new(attrs).save }
        rows.size == 1 ? rows[0] : rows
      end
      
      def update(id, attrs)
        doc = find(id)
        doc.update_attributes(attrs)
      end
      
      def database(name=nil)
        if name.nil?
          @database ||= MongoMapper.default_database
        else
          @database = MongoMapper.connection.db(name)
        end
        
        @database
      end
      
      def collection(name=nil)
        if name.nil?
          @collection ||= database.collection(self.class.to_s.tableize)
        else
          @collection = database.collection(name)
        end
        
        @collection
      end
      
      def key(name, type)
        key = Key.new(name, type)
        keys[key.name] = key
        key
      end
      
      def keys
        @keys ||= HashWithIndifferentAccess.new
      end
      
      def timestamp
        key(:created_at, DateTime)
        key(:updated_at, DateTime)
      end
    end
    
    ####################
    # Instance Methods #
    ####################
    
    def initialize(attrs={})
      self.attributes = attrs
    end
    
    def collection
      self.class.collection
    end
    
    def save
      write_attribute('_id', generate_primary_key) if read_attribute('_id').blank?
      self.attributes = collection.insert(attributes)
      self
    end
    
    def update_attributes(attrs={})
      self.attributes = attrs
      save
    end
    
    def attributes=(attrs)
      attrs.each_pair { |k, v| write_attribute(k, v) if writer?(k) }
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
      name = name.to_s
      name = name.chop if name.ends_with?('=')
      reader?(name)
    end
    
    def [](name)
      read_attribute(name)
    end
    
    def []=(name, value)
      write_attribute(name, value)
    end
    
    def id
      read_attribute('_id')
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
      def generate_primary_key
        XGen::Mongo::Driver::ObjectID.new
      end
      
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