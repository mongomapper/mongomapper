# encoding: UTF-8
module MongoMapper
  module Plugins
    module Sci
      extend ActiveSupport::Concern

      module ClassMethods
        def inherited(subclass)
          key :_type, String unless key?(:_type)
          subclass.instance_variable_set("@single_collection_inherited", [])
          subclass.set_collection_name(collection_name) unless subclass.embeddable?
          @single_collection_inherited << subclass if single_collection_inherited?
          super
        end

        def single_collection_inherited?
          !!@single_collection_inherited
        end

        def query_class_names
          @single_collection_inherited.inject([name]) do |names, subclass|
            names + subclass.query_class_names
          end
        end

        def query(options={})
          super.tap do |query|
            query[:_type] = {'$in' => query_class_names} if single_collection_inherited?
          end
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
