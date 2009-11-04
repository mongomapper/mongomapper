module MongoMapper
  module Associations
    # Base class for keeping track of associations.
    #
    # @private
    class Base
      attr_reader :type, :name, :options, :finder_options

      # Options that should not be considered MongoDB query options/criteria
      AssociationOptions = [:as, :class, :class_name, :dependent, :extend, :foreign_key, :polymorphic]

      def initialize(type, name, options={}, &extension)
        @type, @name, @options, @finder_options = type, name, {}, {}
        options.symbolize_keys!

        options[:extend] = modulized_extensions(extension, options[:extend])

        options.each_pair do |key, value|
          if AssociationOptions.include?(key)
            @options[key] = value
          else
            @finder_options[key] = value
          end
        end
      end

      def class_name
        @class_name ||= begin
          if cn = options[:class_name]
            cn
          elsif many?
            name.to_s.singularize.camelize
          else
            name.to_s.camelize
          end
        end
      end

      def klass
        @klass ||= options[:class] || class_name.constantize
      end

      def many?
        @many_type ||= @type == :many
      end

      def belongs_to?
        @belongs_to_type ||= @type == :belongs_to
      end

      def polymorphic?
        !!@options[:polymorphic]
      end

      def as?
        !!@options[:as]
      end

      def type_key_name
        @type_key_name ||= many? ? '_type' : "#{as}_type"
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

      def embeddable?
        many? && klass.embeddable?
      end

      def proxy_class
        @proxy_class ||= begin
          if many?
            if self.klass.embeddable?
              polymorphic? ? ManyEmbeddedPolymorphicProxy : ManyEmbeddedProxy
            else
              if polymorphic?
                ManyPolymorphicProxy
              elsif as?
                ManyDocumentsAsProxy
              else
                ManyProxy
              end
            end
          else
            polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
          end
        end # end begin
      end # end proxy_class

      private

        # @param [Array<Module, Proc>] extensions a collection of Modules or 
        #   Procs that extend the behaviour of this association.
        def modulized_extensions(*extensions)
          extensions.flatten.compact.map do |extension|
            Proc === extension ? Module.new(&extension) : extension
          end
        end
    end
  end
end
