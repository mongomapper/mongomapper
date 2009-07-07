require 'observer'

module MongoMapper
  module EmbeddedDocument
    class NotImplemented < StandardError; end
    
    def self.included(model)
      model.class_eval do
        extend ClassMethods
        include InstanceMethods
        include Validatable
        include Serialization
      end
    end
    
    module ClassMethods
      class Association
        attr_accessor :name
        
        def initialize(name)
          @name = name.to_s
        end
        
        def klass
          @klass ||= name.classify.constantize
        end
        
        def ivar
          @ivar ||= "@#{name}"
        end
      end
      
      def many(association_name)
        association = Association.new(association_name)
        associations[association.name] = association
        class_eval <<-EOS
          def #{association.name}
            #{association.ivar} ||= []
            #{association.ivar}
          end
        EOS
      end
      
      def associations
        @associations ||= HashWithIndifferentAccess.new
      end
      
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
      
      def ensure_index(name_or_array, options={})
        keys_to_index = if name_or_array.is_a?(Array)
          name_or_array.map { |pair| [pair[0], pair[1]] }
        else
          name_or_array
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
        initialize_embedded_associations(attrs)
        self.attributes = attrs
      end
      
      def attributes=(attrs)
        return if attrs.blank?
        attrs.each_pair do |key_name, value|
          if writer?(key_name)
            write_attribute(key_name, value)
          else
            writer_method ="#{key_name}="
            self.send(writer_method, value) if respond_to?(writer_method)
          end
        end
      end
    
      def attributes
        self.class.keys.inject(HashWithIndifferentAccess.new) do |attributes, key_hash|
          name, key = key_hash
          value = value_for_key(key)
          attributes[name] = value unless value.nil?
          attributes
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
        other.is_a?(self.class) && attributes == other.attributes
      end
      
      def inspect
        attributes_as_nice_string = defined_key_names.collect do |name|
          "#{name}: #{read_attribute(name)}"
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end
    
      alias :respond_to_without_attributes? :respond_to?
      def respond_to?(method, include_private=false)
        return true if reader?(method) || writer?(method) || before_typecast_reader?(method)
        super
      end
      
    private      
      def value_for_key(key)
        if key.native?
          read_attribute(key.name)
        else
          embedded_document = read_attribute(key.name)
          embedded_document && embedded_document.attributes
        end
      end
      
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
      
      def embedded_association_attributes
        attributes = HashWithIndifferentAccess.new
        self.class.associations.each_pair do |name, association|
          attributes[name] = send(name).collect { |item| item.attributes }
        end
        attributes
      end
      
      def initialize_embedded_associations(attrs={})
        self.class.associations.each_pair do |name, association|
          if collection = attrs.delete(name)
            association_value = collection.collect do |item|
              association.klass.new(item)
            end
            instance_variable_set(association.ivar, association_value)
          end
        end
      end
    end
  end
end