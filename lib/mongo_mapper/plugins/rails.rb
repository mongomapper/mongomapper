# encoding: UTF-8
module MongoMapper
  module Plugins
    module Rails
      autoload :ActiveRecordAssociationAdapter, "mongo_mapper/plugins/rails/active_record_association_adapter"
      extend ActiveSupport::Concern

      def to_param
        id.to_s if persisted?
      end

      def to_model
        self
      end

      def to_key
        [id] if persisted?
      end

      def new_record?
        new?
      end

      def read_attribute(name)
        self[name]
      end

      def read_attribute_before_type_cast(name)
        read_key_before_type_cast(name)
      end

      def write_attribute(name, value)
        self[name] = value
      end

      module ClassMethods
        def has_one(*args)
          one(*args)
        end

        def has_many(*args, &extension)
          many(*args, &extension)
        end

        def column_names
          keys.keys
        end

        # Returns returns an ActiveRecordAssociationAdapter for an association. This adapter has an API that is a
        # subset of ActiveRecord::Reflection::AssociationReflection. This allows MongoMapper to be used with the
        # association helpers in gems like simple_form and formtastic.
        def reflect_on_association(name)
          ActiveRecordAssociationAdapter.for_association(associations[name]) if associations[name]
        end
      end
    end
  end
end
