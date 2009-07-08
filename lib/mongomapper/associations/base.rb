module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name, :options

      def initialize(type, name, options = {})
        @options = options
        @type = type
        @name = name
      end

      def klass
        class_name.constantize
      end

      def class_name
        @class_name ||= begin
          if cn = options[:class_name]
            cn
          elsif @type == :many
            name.to_s.singularize.camelize
          else
            name.to_s.camelize
          end
        end
      end

      def ivar
        @ivar ||= "@_#{name}"
      end

      def proxy_class
        case @type
          when :belongs_to
            if @options[:polymorphic]
              PolymorphicBelongsToProxy
            else
              BelongsToProxy
            end
          when :many
            if self.klass.embeddable?
              HasManyEmbeddedProxy
            else
              HasManyProxy
            end
        end
      end
    end
  end
end
