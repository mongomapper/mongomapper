# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class Base
        attr_reader :name, :options, :query_options

        # Options that should not be considered MongoDB query options/criteria
        AssociationOptions = [:as, :class, :class_name, :dependent, :extend, :foreign_key, :in, :polymorphic, :autosave, :touch]

        def initialize(name, options={}, &extension)
          @name, @options, @query_options, @original_options = name.to_sym, {}, {}, options
          options.symbolize_keys!
          options[:extend] = modularized_extensions(extension, options[:extend])
          separate_options_and_conditions
        end

        def class_name
          @class_name ||= options[:class_name] || name.to_s.camelize
        end

        def klass
          @klass ||= options[:class] || class_name.constantize
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
          klass.embeddable?
        end

        def touch?
          !!@options[:touch]
        end

        def type_key_name
          "_type"
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

        def proxy_class
          raise NotImplementedError
        end

        def setup(model)
        end

        def autosave?
          raise NotImplementedError
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
