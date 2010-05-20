module MongoMapper
  module Plugins
    module Sci
      module ClassMethods
        def inherited(subclass)
          key :_type, String unless key?(:_type)
          subclass.instance_variable_set("@single_collection_inherited", true)
          subclass.set_collection_name(collection_name) unless subclass.embeddable?
          super
        end

        def single_collection_inherited?
          @single_collection_inherited == true
        end
      end

      module InstanceMethods
        def initialize(*args)
          super
          write_key :_type, self.class.name if self.class.key?(:_type)
        end
      end
    end
  end
end