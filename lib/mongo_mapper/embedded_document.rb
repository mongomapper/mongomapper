module MongoMapper
  module EmbeddedDocument
    class NotImplemented < StandardError; end
    
    def self.included(model)
      model.class_eval do
        include InstanceMethods
        extend ClassMethods
        include Validatable
        include ActiveSupport::Callbacks
        
        define_callbacks  :before_validation_on_create, :before_validation_on_update,
                          :before_validation,           :after_validation,
                          :before_create,               :after_create, 
                          :before_update,               :after_update,
                          :before_save,                 :after_save,
                          :before_destroy,              :after_destroy
      end
    end
    
    module ClassMethods
      def keys
        @keys ||= HashWithIndifferentAccess.new
      end
      
      def key(name, type, options={})
        key = Key.new(name, type, options)
        keys[key.name] = key
        apply_validations_for(key)
        define_embedded_document_accessors_for(key)
        create_indexes_for(key)
        key
      end
      
      # TODO: remove to_s when ruby driver supports symbols (I sent patch)
      def ensure_index(name_or_array, options={})
        keys_to_index = if name_or_array.is_a?(Array)
          name_or_array.map { |pair| [pair[0].to_s, pair[1]] }
        else
          name_or_array.to_s
        end
        collection.create_index(keys_to_index, options.delete(:unique))
      end
      
    private
      
      def define_embedded_document_accessors_for(key)
        return unless key.embedded_document?
        instance_var = "@#{key.name}"
        
        define_method(key.name) do
          key.get(instance_variable_get(instance_var))
        end
        
        define_method("#{key.name}=") do |value|
          instance_variable_set(instance_var, key.get(value))
        end
      end
      
      def create_indexes_for(key)
        ensure_index key.name if key.options[:index]
      end
      
      def apply_validations_for(key)
        attribute = key.name.to_sym

        if key.options[:required]
          validates_presence_of(attribute)
        end

        if key.options[:numeric]
          number_options = key.type == Integer ? {:only_integer => true} : {}
          validates_numericality_of(attribute, number_options)
        end

        if key.options[:format]
          validates_format_of(attribute, :with => key.options[:format])
        end

        if key.options[:length]
          length_options = case key.options[:length]
          when Integer
            {:minimum => 0, :maximum => key.options[:length]}
          when Range
            {:within => key.options[:length]}
          when Hash
            key.options[:length]
          end

          validates_length_of(attribute, length_options)
        end
      end

    end                                 
                                        
    module InstanceMethods
      
      def initialize(attrs={})
        self.attributes = attrs
      end
      
      def attributes=(attrs)
        attrs.each_pair do |key_name, value|
          write_attribute(key_name, value) if writer?(key_name)
        end
      end
    
      def attributes
        self.class.keys.inject(HashWithIndifferentAccess.new) do |hash, key_hash|
          name, key = key_hash
          value = if key.native?
            read_attribute(name)
          else
            embedded_document = read_attribute(name)
            embedded_document && embedded_document.attributes
          end
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
    
      def before_typecast_reader?(name)
        name.to_s.match(/^(.*)_before_typecast$/) && reader?($1)
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
          read_attribute(attribute)
        elsif writer?(attribute)
          write_attribute(attribute.chop, args[0])
        elsif before_typecast_reader?(attribute)
          read_attribute_before_typecast(attribute.gsub(/_before_typecast$/, ''))
        else
          super
        end
      end
    
      def ==(other)
        self.attributes.all? do |attr|
          key, value = attr
          value == other[key]
        end
      end
      
      def inspect
        attributes_as_nice_string = defined_key_names.collect do |name|
          "#{name}: #{read_attribute(name)}"
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end
    
      def respond_to?(method, include_private=false)
        return true if reader?(method) || writer?(method) || before_typecast_reader?(method)
        super(method, include_private)
      end
      
    private
    
      def read_attribute(name)
        defined_key(name).get(instance_variable_get("@#{name}"))
      end
  
      def read_attribute_before_typecast(name)
        instance_variable_get("@#{name}_before_typecast")
      end
  
      def write_attribute(name, value)
        instance_variable_set "@#{name}_before_typecast", value
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
      
    end
  end
end