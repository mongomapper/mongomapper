require 'observer'

module MongoMapper
  module EmbeddedDocument
    def self.included(model)
      model.class_eval do
        extend ClassMethods
        include InstanceMethods

        extend Associations::ClassMethods
        include Associations::InstanceMethods

        include RailsCompatibility::EmbeddedDocument
        include Validatable
        include Serialization

        extend Validations::Macros

        key :_id, ObjectId
        attr_accessor :_root_document
      end
    end

    module ClassMethods
      def logger
        MongoMapper.logger
      end

      def inherited(subclass)
        unless subclass.embeddable?
          subclass.set_collection_name(collection_name)
        end

        (@subclasses ||= []) << subclass
      end

      def subclasses
        @subclasses
      end

      def keys
        @keys ||= if parent = parent_model
          parent.keys.dup
        else
          HashWithIndifferentAccess.new
        end
      end

      def key(*args)
        key = Key.new(*args)

        if keys[key.name].blank?
          keys[key.name] = key

          create_accessors_for(key)
          create_key_in_subclasses(*args)
          create_validations_for(key)

          key
        end

        key
      end
      
      def object_id_key?(name)
        key = keys[name.to_s]
        key && key.type == ObjectId
      end

      def embeddable?
        !self.ancestors.include?(Document)
      end

      def parent_model
        (ancestors - [self,EmbeddedDocument]).find do |parent_class|
          parent_class.ancestors.include?(EmbeddedDocument)
        end
      end
      
      def to_mongo(instance)
        return nil if instance.nil?
        instance.to_mongo
      end
      
      def from_mongo(instance_or_hash)
        return nil if instance_or_hash.nil?
        
        if instance_or_hash.is_a?(self)
          instance_or_hash
        else
          new(instance_or_hash)
        end
      end
      
    private
      def accessors_module
        module_defined =  if method(:const_defined?).arity == 1 # Ruby 1.9 compat check
                            const_defined?('MongoMapperKeys')
                          else
                            const_defined?('MongoMapperKeys', false)
                          end

        if module_defined
          const_get 'MongoMapperKeys'
        else
          const_set 'MongoMapperKeys', Module.new
        end
      end

      def create_accessors_for(key)
        accessors_module.module_eval <<-end_eval
          def #{key.name}
            read_attribute(:'#{key.name}')
          end

          def #{key.name}_before_typecast
            read_attribute_before_typecast(:'#{key.name}')
          end

          def #{key.name}=(value)
            write_attribute(:'#{key.name}', value)
          end

          def #{key.name}?
            read_attribute(:#{key.name}).present?
          end
        end_eval
        include accessors_module
      end
      
      def create_key_in_subclasses(*args)
        return if subclasses.blank?

        subclasses.each do |subclass|
          subclass.key(*args)
        end
      end

      def create_validations_for(key)
        attribute = key.name.to_sym

        if key.options[:required]
          validates_presence_of(attribute)
        end

        if key.options[:unique]
          validates_uniqueness_of(attribute)
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
      def logger
        self.class.logger
      end
      
      def initialize(attrs={})
        unless attrs.nil?
          self.class.associations.each_pair do |name, association|
            if collection = attrs.delete(name)
              if association.many? && association.klass.embeddable?
                root_document = attrs[:_root_document] || self
                collection.each do |doc|
                  doc[:_root_document] = root_document
                end
              end
              send("#{association.name}=", collection)
            end
          end

          self.attributes = attrs
          
          if respond_to?(:_type=) && self['_type'].blank?
            self._type = self.class.name
          end
        end

        if self.class.embeddable? 
          if read_attribute(:_id).blank?
            write_attribute :_id, Mongo::ObjectID.new
            @new_document = true
          else
            @new_document = false
          end
        end
      end

      def new?
        !!@new_document
      end
      
      def to_param
        id
      end

      def attributes=(attrs)
        return if attrs.blank?
        attrs.each_pair do |name, value|
          writer_method = "#{name}="

          if respond_to?(writer_method)
            self.send(writer_method, value)
          else
            self[name.to_s] = value
          end
        end
      end

      def attributes
        attrs = HashWithIndifferentAccess.new
        
        embedded_keys.each do |key|
          attrs[key.name] = read_attribute(key.name).try(:attributes)
        end
        
        non_embedded_keys.each do |key|
          attrs[key.name] = read_attribute(key.name)
        end
        
        embedded_associations.each do |association|
          documents = instance_variable_get(association.ivar)
          next if documents.nil?
          attrs[association.name] = documents.collect { |doc| doc.attributes }
        end
        
        attrs
      end
      
      def to_mongo
        attrs = HashWithIndifferentAccess.new
        
        _keys.each_pair do |name, key|
          value = key.set(read_attribute(key.name))
          attrs[name] = value unless value.nil?
        end
        
        embedded_associations.each do |association|
          if documents = instance_variable_get(association.ivar)
            attrs[association.name] = documents.map { |document| document.to_mongo }
          end
        end
        
        attrs
      end

      def clone
        clone_attributes = self.attributes
        clone_attributes.delete("_id")
        self.class.new(clone_attributes)
      end

      def [](name)
        read_attribute(name)
      end

      def []=(name, value)
        ensure_key_exists(name)
        write_attribute(name, value)
      end

      def ==(other)
        other.is_a?(self.class) && _id == other._id
      end

      def id
        read_attribute(:_id).to_s
      end

      def id=(value)
        @using_custom_id = true
        write_attribute :_id, value
      end

      def using_custom_id?
        !!@using_custom_id
      end

      def inspect
        attributes_as_nice_string = key_names.collect do |name|
          "#{name}: #{read_attribute(name).inspect}"
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end

      def save
        if _root_document
          _root_document.save
        end
      end
      
      def save!
        if _root_document
          _root_document.save!
        end
      end

      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end

      private
        def _keys
          self.metaclass.keys
        end
        
        def key_names
          _keys.keys
        end
        
        def non_embedded_keys
          _keys.values.select { |key| !key.embeddable? }
        end
        
        def embedded_keys
          _keys.values.select { |key| key.embeddable? }
        end
        
        def ensure_key_exists(name)
          self.metaclass.key(name) unless respond_to?("#{name}=")
        end

        def read_attribute(name)
          if key = _keys[name]
            value = key.get(instance_variable_get("@#{name}"))
            instance_variable_set "@#{name}", value if !frozen?
            value
          else
            raise KeyNotFound, "Could not find key: #{name.inspect}"
          end
        end

        def read_attribute_before_typecast(name)
          instance_variable_get("@#{name}_before_typecast")
        end

        def write_attribute(name, value)
          key = _keys[name]
          instance_variable_set "@#{name}_before_typecast", value
          instance_variable_set "@#{name}", key.set(value)          
        end
        
        def embedded_associations
          self.class.associations.select do |name, association|
            association.embeddable?
          end.map do |name, association|
            association
          end
        end
    end # InstanceMethods
  end # EmbeddedDocument
end # MongoMapper
