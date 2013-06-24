# encoding: UTF-8
require 'mongo_mapper/plugins/keys/key'

module MongoMapper
  module Plugins
    module Keys
      extend ActiveSupport::Concern

      IS_RUBY_1_9 = method(:const_defined?).arity == 1

      included do
        extend ActiveSupport::DescendantsTracker
        key :_id, ObjectId, :default => lambda { BSON::ObjectId.new }
      end

      module ClassMethods
        def inherited(descendant)
          descendant.instance_variable_set(:@keys, keys.dup)
          super
        end

        def keys
          @keys ||= {}
        end

        def default_keys
          @default_keys ||= @keys.values.select(&:default?)
        end

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
            create_accessors_for(key)
            create_key_in_descendants(*args)
            create_indexes_for(key)
            create_validations_for(key)
          end
        end

        def key?(key)
          keys.key? key.to_s
        end

        def using_object_id?
          object_id_key?(:_id)
        end

        def object_id_keys
          @object_id_keys ||= keys.keys.select { |key| keys[key].type == ObjectId }.map(&:to_sym)
        end

        def object_id_key?(name)
          object_id_keys.include?(name.to_sym)
        end

        def to_mongo(instance)
          instance && instance.to_mongo
        end

        def from_mongo(value)
          value && (value.instance_of?(self) ? value : load(value))
        end

        # load is overridden in identity map to ensure same objects are loaded
        def load(attrs)
          return nil if attrs.nil?
          begin
            attrs['_type'] ? attrs['_type'].constantize : self
          rescue NameError
            self
          end.allocate.initialize_from_database(attrs)
        end

        private
          def key_accessors_module_defined?
            if IS_RUBY_1_9
              const_defined?('MongoMapperKeys')
            else
              const_defined?('MongoMapperKeys', false)
            end
          end

          def accessors_module
            if key_accessors_module_defined?
              const_get 'MongoMapperKeys'
            else
              const_set 'MongoMapperKeys', Module.new
            end
          end

          def create_accessors_for(key)
            accessors_module.module_eval <<-end_eval
              def #{key.name}
                read_key(:#{key.name})
              end

              def #{key.name}=(value)
                write_key(:#{key.name}, value)
              end

              def #{key.name}?
                read_key(:#{key.name}).present?
              end
            end_eval

            if block_given?
              accessors_module.module_eval do
                yield
              end
            end

            include accessors_module
          end

          def create_key_in_descendants(*args)
            descendants.each { |descendant| descendant.key(*args) }
          end

          def create_indexes_for(key)
            if key.options[:index] && !key.embeddable?
              warn "[DEPRECATION] :index option when defining key #{key.name.inspect} is deprecated. Put indexes in `db/indexes.rb`"
              ensure_index key.name
            end
          end

          def create_validations_for(key)
            attribute = key.name.to_sym

            if key.options[:required]
              if key.type == Boolean
                validates_inclusion_of attribute, :in => [true, false]
              else
                validates_presence_of(attribute)
              end
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

            if key.options[:in]
              validates_inclusion_of(attribute, :in => key.options[:in])
            end

            if key.options[:not_in]
              validates_exclusion_of(attribute, :in => key.options[:not_in])
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

      def initialize(attrs={})
        @_new = true
        initialize_default_values(attrs)
        self.attributes = attrs
      end

      def initialize_from_database(attrs={})
        @_new = false
        initialize_default_values(attrs)
        load_from_database(attrs)
        self
      end

      def persisted?
        !new? && !destroyed?
      end

      def attributes=(attrs)
        return if attrs == nil || attrs.blank?

        attrs.each_pair do |key, value|
          if respond_to?(:"#{key}=")
            self.send(:"#{key}=", value)
          else
            self[key] = value
          end
        end
      end

      def attributes
        HashWithIndifferentAccess.new.tap do |attrs|
          keys.each do |name, key|
            if key.type == ObjectId || !self[key.name].nil?
              value = key.set(self[key.name])
              attrs[name] = value
            end
          end

          embedded_associations.each do |association|
            if documents = instance_variable_get(association.ivar)
              if association.instance_of?(Associations::OneAssociation)
                attrs[association.name] = documents.to_mongo
              else
                attrs[association.name] = documents.map(&:to_mongo)
              end
            end
          end
        end
      end
      alias :to_mongo :attributes

      def assign(attrs={})
        warn "[DEPRECATION] #assign is deprecated, use #attributes="
        self.attributes = attrs
      end

      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end

      def update_attributes!(attrs={})
        self.attributes = attrs
        save!
      end

      def update_attribute(name, value)
        self.send(:"#{name}=", value)
        save(:validate => false)
      end

      def id
        self[:_id]
      end

      def id=(value)
        if self.class.using_object_id?
          value = ObjectId.to_mongo(value)
        end

        self[:_id] = value
      end

      def keys
        self.class.keys
      end

      def read_key(key_name)
        instance_key = :"@#{key_name}"
        if instance_variable_defined? instance_key
          instance_variable_get instance_key
        elsif key = keys[key_name.to_s]
          value = key.get instance_variable_get(instance_key)
          instance_variable_set instance_key, value
        end
      end

      alias_method :[], :read_key

      def []=(name, value)
        write_key(name, value)
      end

      def key_names
        @key_names ||= keys.keys
      end

      def non_embedded_keys
        @non_embedded_keys ||= keys.values.select { |key| !key.embeddable? }
      end

      def embedded_keys
        @embedded_keys ||= keys.values.select(&:embeddable?)
      end

      private
        def load_from_database(attrs)
          return if attrs == nil || attrs.blank?

          # Init the keys ivar. Due to the volume of times this method is called, we don't want it in a method.
          @_mm_keys = self.class.keys

          attrs.each do |key, value|
            if !@_mm_keys.key?(key) && respond_to?(:"#{key}=")
              self.send(:"#{key}=", value)
            else
              internal_write_key key, value, false
            end
          end
        end

        def set_parent_document(key, value)
          if key.type and value.instance_of?(key.type) && key.embeddable? && value.respond_to?(:_parent_document)
            value._parent_document = self
          end
        end

        # This exists to be patched over by plugins, while letting us still get to the undecorated
        # version of the method.
        def write_key(name, value)
          internal_write_key(name.to_s, value)
        end

        def internal_write_key(name, value, cast = true)
          key         = @_mm_keys[name] || self.class.key(name)
          as_mongo    = cast ? key.set(value) : value
          as_typecast = key.get(as_mongo)
          if key.embeddable?
            set_parent_document(key, value)
            set_parent_document(key, as_typecast)
          end
          instance_variable_set key.ivar, as_typecast
          @attributes = nil
        end

        def initialize_default_values(except = {})
          # Init the keys ivar. Due to the volume of times this method is called, we don't want it in a method.
          @_mm_keys = self.class.keys

          self.class.default_keys.each do |key|
            next if except && except.key?(key.name)
            internal_write_key key.name, key.default_value, false
          end
        end
      #end private
    end
  end
end
