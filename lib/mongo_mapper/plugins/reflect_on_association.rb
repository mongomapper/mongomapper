# encoding: UTF-8
require 'mongo_mapper/plugins/reflect_on_association/active_record_association_adapter'

module MongoMapper
  module Plugins
    # Provides a reflect_on_association method that returns an ActiveRecordAssociationAdapter for an association.
    # This adapter has an API that is a subset of ActiveRecord::Reflection::AssociationReflection. This allows
    # MongoMapper to be used with the association helpers in gems like simple_form and formtastic.
    module ReflectOnAssociation
      extend ActiveSupport::Concern

      module ClassMethods
        def reflect_on_association(name)
          ActiveRecordAssociationAdapter.for_association(associations[name]) if associations[name]
        end
      end
    end
  end
end