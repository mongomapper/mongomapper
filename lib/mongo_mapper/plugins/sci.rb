# encoding: UTF-8
module MongoMapper
  module Plugins
    module Sci
      extend ActiveSupport::Concern

      included do
        extend ActiveSupport::DescendantsTracker
      end

      module ClassMethods
        def inherited(subclass)
          key :_type, String unless key?(:_type)
          super
          subclass.single_collection_parent = self
          subclass.instance_variable_set("@single_collection_inherited", true)
        end

        def single_collection_root
          parent = single_collection_parent || self
          root = parent

          while parent
            parent = parent.single_collection_parent
            root = parent unless parent.nil?
          end

          root
        end

        def set_collection_name(name)
          if single_collection_inherited?
            single_collection_parent = nil
            @single_collection_inherited = false
          end
          super
        end

        def single_collection_parent
          @single_collection_parent
        end

        def single_collection_parent=(parent)
          @single_collection_parent = parent
        end

        def single_collection_inherited?
          !!(@single_collection_inherited ||= false)
        end

        def query(options={})
          super.tap do |query|
            query[:_type] = {'$in' => [name] + descendants.map(&:name)} if single_collection_inherited?
          end
        end
      end

      def initialize(*args)
        super
        write_key :_type, self.class.name if self.class.key?(:_type)
      end
    end
  end
end
