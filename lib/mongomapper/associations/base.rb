module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name, :options

      def initialize(type, name, options = {})
        @options = options
        @type = type
        @name = name
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
      
      def type_key_name
        @type_key_name ||= many? ? '_type' : "#{name}_type"
      end
      
      def belongs_to_key_name
        "#{name}_id"
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
              polymorphic? ? ManyPolymorphicProxy : ManyProxy
            end
          else
            polymorphic? ? BelongsToPolymorphicProxy : BelongsToProxy
          end
        end # end begin
      end # end proxy_class
    end
  end
end
