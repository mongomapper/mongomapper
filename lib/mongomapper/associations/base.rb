module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name, :options
      attr_accessor :value

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
    end
  end
end
