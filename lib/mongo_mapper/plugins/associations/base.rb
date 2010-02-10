module MongoMapper
  module Plugins
    module Associations
      class Base
        attr_reader :type, :name, :options, :query_options

        # Options that should not be considered MongoDB query options/criteria
        AssociationOptions = [:as, :class, :class_name, :dependent, :extend, :foreign_key, :in, :polymorphic]

        def initialize(type, name, options={}, &extension)
          @type, @name, @options, @query_options, @original_options = type, name, {}, {}, options
          options.symbolize_keys!
          options[:extend] = modularized_extensions(extension, options[:extend])
          separate_options_and_conditions
        end

        def class_name
          return @class_name if defined?(@class_name)
          
          @class_name = 
            if cn = options[:class_name]
              cn
            elsif many?
              name.to_s.singularize.camelize
            else
              name.to_s.camelize
            end
        end

        def klass
          @klass ||= options[:class] || class_name.constantize
        end

        def many?
          @type == :many
        end

        def belongs_to?
          @type == :belongs_to
        end

        def one?
          @type == :one
        end

        def polymorphic?
          !!@options[:polymorphic]
        end

        def as?
          !!@options[:as]
        end

        def in_array?
          !!@options[:in]
        end

        def embeddable?
          many? && klass.embeddable?
        end

        def type_key_name
          many? ? '_type' : "#{as}_type"
        end

        def as
          @options[:as] || self.name
        end

        def foreign_key
          @options[:foreign_key] || "#{name}_id"
        end

        def ivar
          @ivar ||= "@_#{name}"
        end

        # hate this, need to revisit
        def proxy_class
          return @proxy_class if defined?(@proxy_class)
          
          @proxy_class = 
            if many?
              if klass.embeddable?
                polymorphic? ? ManyEmbeddedPolymorphicProxy : ManyEmbeddedProxy
              else
                if polymorphic?
                  ManyPolymorphicProxy
                elsif as?
                  ManyDocumentsAsProxy
                elsif in_array?
                  InArrayProxy
                else
                  ManyDocumentsProxy
                end
              end
            elsif one?
              OneProxy
            else
              polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
            end
        end

        private
          def separate_options_and_conditions
            @original_options.each_pair do |key, value|
              if AssociationOptions.include?(key)
                @options[key] = value
              else
                @query_options[key] = value
              end
            end
          end

          def modularized_extensions(*extensions)
            extensions.flatten.compact.map do |extension|
              Proc === extension ? Module.new(&extension) : extension
            end
          end
      end
    end
  end
end
