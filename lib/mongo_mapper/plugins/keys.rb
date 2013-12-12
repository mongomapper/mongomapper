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

        def dynamic_keys
          @dynamic_keys ||= Hash[*unaliased_keys.select {|k, v| v.dynamic? }.flatten(1)]
        end

        def defined_keys
          @defined_keys ||= Hash[*unaliased_keys.select {|k, v| !v.dynamic? }.flatten(1)]
        end

        def unaliased_keys
          @unaliased_keys ||= Hash[*keys.select {|k, v| k == v.name }.flatten(1)]
        end

        def dealias_keys(hash)
          out = {}
          hash.each do |k, v|
            key = keys[k.to_s]
            name = key && key.abbr || k
            out[name] = k.to_s.match(/^\$/) && v.is_a?(Hash) ? dealias_keys(v) : v
          end
          out
        end

        def dealias_key(name)
          key = keys[name.to_s]
          key && key.abbr || k
        end

        alias_method :dealias, :dealias_keys
        alias_method :unalias, :dealias_keys

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
            keys[key.abbr] = key if key.abbr
            create_accessors_for(key) if key.valid_ruby_name?
            create_key_in_descendants(*args)
            create_indexes_for(key)
            create_validations_for(key)
            @dynamic_keys = @defined_keys = @unaliased_keys = @object_id_keys = nil
          end
        end

        def persisted_name(name)
          if key = keys[name.to_s]
            key.persisted_name
          else
            name
          end
        end
        alias_method :abbr, :persisted_name

        def key?(key)
          keys.key? key.to_s
        end

        def using_object_id?
          object_id_key?(:_id)
        end

        def object_id_keys
          @object_id_keys ||= unaliased_keys.keys.select { |key| keys[key].type == ObjectId }.map(&:to_sym)
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
        def load(attrs, with_cast = false)
          return nil if attrs.nil?
          begin
            attrs['_type'] ? attrs['_type'].constantize : self
          rescue NameError
            self
          end.allocate.initialize_from_database(attrs, with_cast)
        end

        private
          def key_accessors_module_defined?
            # :nocov:
            if IS_RUBY_1_9
              const_defined?('MongoMapperKeys')
            else
              const_defined?('MongoMapperKeys', false)
            end
            # :nocov:
          end

          def accessors_module
            if key_accessors_module_defined?
              const_get 'MongoMapperKeys'
            else
              const_set 'MongoMapperKeys', Module.new
            end
          end

          def create_accessors_for(key)
            accessors = ""
            if key.read_accessor?
              accessors << <<-end_eval
                def #{key.name}
                  read_key(:#{key.name})
                end

                def #{key.name}_before_type_cast
                  read_key_before_type_cast(:#{key.name})
                end
              end_eval
            end

            if key.write_accessor?
              accessors << <<-end_eval
                def #{key.name}=(value)
                  write_key(:#{key.name}, value)
                end
              end_eval
            end

            if key.predicate_accessor?
              accessors << <<-end_eval
                def #{key.name}?
                  read_key(:#{key.name}).present?
                end
              end_eval
            end

            if block_given?
              accessors_module.module_eval do
                yield
              end
            end

            accessors_module.module_eval accessors
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
        init_ivars
        initialize_default_values(attrs)
        self.attributes = attrs
        yield self if block_given?
      end

      def initialize_from_database(attrs={}, with_cast = false)
        @_new = false
        init_ivars
        initialize_default_values(attrs)
        load_from_database(attrs, with_cast)
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

      def to_mongo(include_abbreviatons = true)
        BSON::OrderedHash.new.tap do |attrs|
          self.class.unaliased_keys.each do |name, key|
            value = self.read_key(key.name)
            if key.type == ObjectId || !value.nil?
              attrs[include_abbreviatons && key.persisted_name || name] = key.set(value)
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

      def attributes
        to_mongo(false).with_indifferent_access
      end

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
        key_name_sym = key_name.to_sym
        if @_dynamic_attributes && @_dynamic_attributes.key?(key_name_sym)
          @_dynamic_attributes[key_name_sym]
        elsif key = keys[key_name.to_s]
          if key.ivar && instance_variable_defined?(key.ivar)
            value = instance_variable_get(key.ivar)
          else
            if key.ivar
              instance_variable_set key.ivar, key.get(nil)
            else
              @_dynamic_attributes[key_name_sym] = key.get(nil)
            end
          end
        end
      end

      alias_method :[], :read_key
      alias_method :attribute, :read_key

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

      protected

      def unalias_key(name)
        name = name.to_s
        if key = keys[name]
          key.name
        else
          name
        end
      end

      private

        def init_ivars
          @__mm_keys = self.class.keys                                # Not dumpable
          @__mm_default_keys = @__mm_keys.values.select(&:default?)   # Not dumpable
          @_dynamic_attributes = {}                                      # Dumpable
        end

        def load_from_database(attrs, with_cast = false)
          return if attrs == nil || attrs.blank?

          attrs.each do |key, value|
            if !@__mm_keys.key?(key) && respond_to?(:"#{key}=")
              self.send(:"#{key}=", value)
            else
              internal_write_key key, value, with_cast
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
          init_ivars unless @__mm_keys
          internal_write_key(name.to_s, value)
        end

        def internal_write_key(name, value, cast = true)
          key         = @__mm_keys[name] || dynamic_key(name)
          as_mongo    = cast ? key.set(value) : value
          as_typecast = key.get(as_mongo)
          if key.ivar
            if key.embeddable?
              set_parent_document(key, value)
              set_parent_document(key, as_typecast)
            end
            instance_variable_set key.ivar, as_typecast
          else
            @_dynamic_attributes[key.name.to_sym] = as_typecast
          end
        end

        def dynamic_key(name)
          self.class.key(name, :__dynamic => true)
        end

        def initialize_default_values(except = {})
          @__mm_default_keys.each do |key|
            if !(except && except.key?(key.name))
              internal_write_key key.name, key.default_value, false
            end
          end
        end
      #end private
    end
  end
end
