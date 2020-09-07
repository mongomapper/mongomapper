# encoding: UTF-8
module MongoMapper
  module Plugins
    module Dirty
      extend ActiveSupport::Concern
      include ::ActiveModel::Dirty

      module ClassMethods
        def create_accessors_for(key)
          super.tap do
            define_attribute_methods([key.name])
          end
        end
      end

      def create_or_update(*)
        super.tap do
          changes_applied
        end
      end

      def reload!
        super.tap do
          clear_changes_information
        end
      end

      def rollback!
        super.tap do
          restore_attributes
        end
      end

    private

      def write_key(key_name, value)
        key_name = unalias_key(key_name)

        if !keys.key?(key_name)
          super
        else
          # find the MongoMapper::Plugins::Keys::Key
          _, key = keys.detect { |n, v| n == key_name }

          # typecast to the new value
          old_value = read_key(key_name)
          new_value = key.type.to_mongo(value)

          # only mark changed if really changed value (after typecasting)
          unless old_value == new_value
            attribute_will_change!(key_name)
          end

          super
        end
      end
    end
  end
end
