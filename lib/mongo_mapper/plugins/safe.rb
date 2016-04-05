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

        def collection_options
          if @safe_options
            super.merge(write: Utils.get_safe_options(safe: @safe_options))
          else
            super
          end
        end

      end


    end
  end
end