# encoding: UTF-8
module MongoMapper
  module Plugins
    module Safe
      extend ActiveSupport::Concern

      module ClassMethods
        attr_reader :safe_options

        def inherited(subclass)
          super
          subclass.safe(safe_options) if safe?
        end

        def safe(options = true)
          @safe_options = options
        end

        def safe?
          @safe_options ||= nil
          !!@safe_options
        end
      end

      def save_to_collection(options={})
        options[:safe] = self.class.safe_options if !options.key?(:safe) && self.class.safe?
        super
      end
    end
  end
end