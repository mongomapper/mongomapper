# encoding: UTF-8
module MongoMapper
  module Plugins
    module Dirty
      extend ActiveSupport::Concern

      include ::ActiveModel::Dirty

      def initialize(*)
        # never register initial id assignment as a change
        super.tap { changed_attributes.delete('_id') }
      end

      def initialize_from_database(*)
        super.tap { changed_attributes.clear }
      end

      def save(*)
        clear_changes { super }
      end

      def reload(*)
        super.tap { clear_changes }
      end

      protected

      def attribute_method?(attr)
        # This overrides ::ActiveSupport::Dirty#attribute_method? to allow attributes to be any key
        # in the attributes hash ( default ) or any key defined on the model that may not yet have
        # had a value stored in the attributes collection.
        super || key_names.include?(attr)
      end

      def clear_changes
        previous = changes
        (block_given? ? yield : true).tap do |result|
          unless result == false #failed validation; nil is OK.
            @previously_changed = previous
            changed_attributes.clear
          end
        end
      end

      private

      def write_key(key, value)
        key = key.to_s
        attribute_will_change!(key) unless attribute_changed?(key)
        super(key, value).tap do
          changed_attributes.delete(key) unless attribute_value_changed?(key)
        end
      end

      def attribute_value_changed?(key_name)
        attribute_was(key_name) != read_key(key_name)
      end
    end
  end
end