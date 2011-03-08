# encoding: UTF-8
require 'set'

module MongoMapper
  module Support
    module DescendantAppends
      def included(model = nil, &block)
        if model
          extra_extensions.each { |extension| model.extend(extension) }
          extra_inclusions.each { |inclusion| model.send(:include, inclusion) }
          direct_descendants << model
        end
        super
      end

      # @api public
      def append_extensions(*extensions)
        warn "[DEPRECATED] append_extensions is deprecated. Use #plugin with a module that extends ActiveSupport::Concern."
        extra_extensions.concat(extensions)
        direct_descendants.each do |model|
          extensions.each { |extension| model.extend(extension) }
        end
      end

      # @api public
      def append_inclusions(*inclusions)
        warn "[DEPRECATED] append_inclusions is deprecated. Use #plugin with a module that extends ActiveSupport::Concern."
        extra_inclusions.concat(inclusions)
        direct_descendants.each do |model|
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