# encoding: UTF-8
module MongoMapper
  module Plugins
    module Safe
      extend ActiveSupport::Concern

      module ClassMethods
        def inherited(subclass)
          super
          subclass.safe if safe?
        end

        def safe
          @safe = true
        end

        def safe?
          @safe == true
        end
      end

      def save_to_collection(options={})
        options[:safe] = self.class.safe? unless options.key?(:safe)
        super
      end
    end
  end
end