# encoding: UTF-8
require 'set'

module MongoMapper
  module Support
    module DescendantAppends
      def included(model)
        extra_extensions.each { |extension| model.extend(extension) }
        extra_inclusions.each { |inclusion| model.send(:include, inclusion) }
        descendants << model
      end

      # @api public
      def descendants
        @descendants ||= Set.new
      end

      # @api public
      def append_extensions(*extensions)
        extra_extensions.concat(extensions)
        descendants.each do |model|
          extensions.each { |extension| model.extend(extension) }
        end
      end

      # @api public
      def append_inclusions(*inclusions)
        extra_inclusions.concat(inclusions)
        descendants.each do |model|
          inclusions.each { |inclusion| model.send(:include, inclusion) }
        end
      end

      # @api private
      def extra_extensions
        @extra_extensions ||= []
      end

      # @api private
      def extra_inclusions
        @extra_inclusions ||= []
      end
    end
  end
end