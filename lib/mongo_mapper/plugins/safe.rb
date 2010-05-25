# encoding: UTF-8
module MongoMapper
  module Plugins
    module Safe
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

      module InstanceMethods
        def save_to_collection(options={})
          options[:safe] = self.class.safe? unless options.key?(:safe)
          super
        end
      end
    end
  end
end