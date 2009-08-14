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

        key :_id, String
      end
    end

    module ClassMethods
      def inherited(subclass)
        unless subclass.embeddable?
          subclass.collection(self.collection.name)
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

      def key(name, type, options={})
        key = Key.new(name, type, options)
        keys[key.name] = key

        create_accessors_for(key)
        add_to_subclasses(name, type, options)
        apply_validations_for(key)
        create_indexes_for(key)

        key
      end

      def add_to_subclasses(name, type, options)
        return if subclasses.blank?

        subclasses.each do |subclass|
          subclass.key name, type, options
        end
      end

      def ensure_index(name_or_array, options={})
        keys_to_index = if name_or_array.is_a?(Array)
          name_or_array.map { |pair| [pair[0], pair[1]] }
        else
          name_or_array
        end

        collection.create_index(keys_to_index, options.delete(:unique))
      end

      def embeddable?
        !self.ancestors.include?(Document)
      end

      def parent_model
        if parent = ancestors[1]
          parent if parent.ancestors.include?(EmbeddedDocument)
        end
      end

    private
      def create_accessors_for(key)
        define_method(key.name) do
          read_attribute(key.name)
        end

        define_method("#{key.name}_before_typecast") do
          read_attribute_before_typecast(key.name)
        end

        define_method("#{key.name}=") do |value|
          write_attribute(key.name, value)
        end

        define_method("#{key.name}?") do
          read_attribute(key.name).present?
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
      def initialize(attrs={})
        unless attrs.nil?
          self.class.associations.each_pair do |name, association|
            if collection = attrs.delete(name)
              send("#{association.name}=", collection)
            end
          end

          self.attributes = attrs
        end

        if self.class.embeddable? && read_attribute(:_id).blank?
          write_attribute :_id, XGen::Mongo::Driver::ObjectID.new.to_s
        end
      end

      def attributes=(attrs)
        return if attrs.blank?
        attrs.each_pair do |key, value|
          method = "#{key}="
          if !respond_to?(method)
            self.class.key(key, nil)
          end
          self.send(method, value)
        end
      end

      def attributes
        returning HashWithIndifferentAccess.new do |attributes|
          self.class.keys.each_pair do |name, key|
            value = value_for_key(key)
            attributes[name] = value unless value.nil?
          end

          attributes.merge!(embedded_association_attributes)
        end
      end

      def assign_attributes(white_list, values)
        white_list.each do |key|
          send("#{key}=", values[key]) if values.has_key?(key)
        end
      end

      def [](name)
        read_attribute(name)
      end

      def []=(name, value)
        write_attribute(name, value)
      end

      def ==(other)
        other.is_a?(self.class) && id == other.id
      end

      def id
        read_attribute(:_id)
      end

      def id=(value)
        @using_custom_id = true
        write_attribute :_id, value
      end

      def using_custom_id?
        !!@using_custom_id
      end

      def inspect
        attributes_as_nice_string = self.class.keys.keys.collect do |name|
          "#{name}: #{read_attribute(name)}"
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
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
          value = self.class.keys[name].get(instance_variable_get("@#{name}"))
          instance_variable_set "@#{name}", value if !frozen?
          value
        end

        def read_attribute_before_typecast(name)
          instance_variable_get("@#{name}_before_typecast")
        end

        def write_attribute(name, value)
          instance_variable_set "@#{name}_before_typecast", value
          instance_variable_set "@#{name}", self.class.keys[name].set(value)
        end

        def embedded_association_attributes
          returning HashWithIndifferentAccess.new do |attrs|
            self.class.associations.each_pair do |name, association|
              next unless association.embeddable?
              next unless documents = instance_variable_get(association.ivar)

              attrs[name] = documents.collect { |doc| doc.attributes }
            end
          end
        end
    end # InstanceMethods
  end # EmbeddedDocument
end # MongoMapper
