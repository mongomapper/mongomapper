module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name, :options, :finder_options
      
      # Options that should not be considered MongoDB query options/criteria
      AssociationOptions = [:as, :class_name, :dependent, :extend, :foreign_key, :polymorphic]
      
      def initialize(type, name, options={})
        @type, @name = type, name
        @options, @finder_options = {}, {}
        
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
        @klass ||= class_name.constantize
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
    end
  end
end
