module MongoMapper
  module Plugins
    module Keys
      def self.configure(model)
        model.key :_id, ObjectId
      end

      module ClassMethods
        def inherited(descendant)
          descendant.instance_variable_set(:@keys, keys.dup)
          super
        end

        def keys
          @keys ||= HashWithIndifferentAccess.new
        end

        def key(*args)
          key = Key.new(*args)
          keys[key.name] = key

          create_accessors_for(key)
          create_key_in_descendants(*args)
          create_indexes_for(key)
          create_validations_for(key)

          key
        end

        def using_object_id?
          object_id_key?(:_id)
        end

        def object_id_key?(name)
          key = keys[name.to_s]
          key && key.type == ObjectId
        end

        def to_mongo(instance)
          return nil if instance.nil?
          instance.to_mongo
        end

        def from_mongo(value)
          return nil if value.nil?
          value.is_a?(self) ? value : load(value)
        end

        # load is overridden in identity map to ensure same objects are loaded
        def load(attrs)
          begin
            klass = attrs['_type'].present? ? attrs['_type'].constantize : self
            klass.new(attrs, true)
          rescue NameError
            new(attrs, true)
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
                read_key(:#{key.name})
              end

              def #{key.name}_before_typecast
                read_key_before_typecast(:#{key.name})
              end

              def #{key.name}=(value)
                write_key(:#{key.name}, value)
              end

              def #{key.name}?
                read_key(:#{key.name}).present?
              end
            end_eval

            include accessors_module
          end

          def create_key_in_descendants(*args)
            return if descendants.blank?
            descendants.each { |descendant| descendant.key(*args) }
          end

          def create_indexes_for(key)
            ensure_index key.name if key.options[:index] && !key.embeddable?
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

            if key.options[:in]
              validates_inclusion_of(attribute, :within => key.options[:in])
            end

            if key.options[:not_in]
              validates_exclusion_of(attribute, :within => key.options[:not_in])
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
        def initialize(attrs={}, from_database=false)
          unless attrs.nil?
            provided_keys = attrs.keys.map { |k| k.to_s }
            unless provided_keys.include?('_id') || provided_keys.include?('id')
              write_key :_id, Mongo::ObjectID.new
            end
          end

          assign_type_if_present

          if from_database
            @new = false
            self.attributes = attrs
          else
            @new = true
            assign(attrs)
          end
        end

        def new?
          @new
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

          keys.each_pair do |name, key|
            value = key.set(self[key.name])
            attrs[name] = value
          end

          embedded_associations.each do |association|
            if documents = instance_variable_get(association.ivar)
              attrs[association.name] = documents.map { |document| document.to_mongo }
            end
          end

          attrs
        end
        alias :to_mongo :attributes

        def assign(attrs={})
          self.attributes = attrs
        end

        def update_attributes(attrs={})
          assign(attrs)
          save
        end

        def update_attributes!(attrs={})
          assign(attrs)
          save!
        end

        def id
          _id
        end
        
        def id=(value)
          if self.class.using_object_id?
            value = MongoMapper.normalize_object_id(value)
          end

          self[:_id] = value
        end

        def [](name)
          read_key(name)
        end

        def []=(name, value)
          ensure_key_exists(name)
          write_key(name, value)
        end

        # @api public
        def keys
          self.class.keys
        end

        # @api private?
        def key_names
          keys.keys
        end

        # @api private?
        def non_embedded_keys
          keys.values.select { |key| !key.embeddable? }
        end

        # @api private?
        def embedded_keys
          keys.values.select { |key| key.embeddable? }
        end

        private
          def assign_type_if_present
            self._type = self.class.name if respond_to?(:_type=)
          end
          
          def ensure_key_exists(name)
            self.class.key(name) unless respond_to?("#{name}=")
          end

          def read_key(name)
            if key = keys[name]
              var_name = "@#{name}"
              value = key.get(instance_variable_get(var_name))
              instance_variable_set(var_name, value)
            else
              raise KeyNotFound, "Could not find key: #{name.inspect}"
            end
          end

          def read_key_before_typecast(name)
            instance_variable_get("@#{name}_before_typecast")
          end

          def write_key(name, value)
            key = keys[name]
            instance_variable_set "@#{name}_before_typecast", value
            instance_variable_set "@#{name}", key.set(value)
          end
      end
      
      class Key
        attr_accessor :name, :type, :options, :default_value

        def initialize(*args)
          options = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options || {}).symbolize_keys
          self.default_value = self.options.delete(:default)
        end

        def ==(other)
          @name == other.name && @type == other.type
        end

        def embeddable?
          type.respond_to?(:embeddable?) && type.embeddable? ? true : false
        end

        def number?
          [Integer, Float].include?(type)
        end

        def get(value)
          if value.nil? && !default_value.nil?
            return default_value
          end

          type.from_mongo(value)
        end

        def set(value)
          type.to_mongo(value)
        end
      end
    end
  end
end
