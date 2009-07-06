module MongoMapper
  module Associations
    class Base
      attr_reader :type, :name

      def initialize(type, name, options = {})
        @options = options
        @type = type
        @name = name
      end

      def klass
        klass_name.constantize
      end

      def klass_name
        @klass_name ||= (options[:class_name] || name.to_s.camelize)
      end

      def ivar
        @ivar ||= "@_#{name}"
      end
    end
  end
end
