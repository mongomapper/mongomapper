# encoding: UTF-8
module MongoMapper
  module Plugins
    module Dirty
      extend ActiveSupport::Concern

      include ::ActiveModel::Dirty

      def initialize(*)
        # never register initial id assignment as a change
        # Chaining super into tap breaks implicit block passing in Ruby 1.8
        doc = super
        doc.tap { changed_attributes.delete('_id') }
      end

      def save(*)
        clear_changes { super }
      end

      def reload(*)
        doc = super
        doc.tap { clear_changes }
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

      protected

      # We don't call super here to avoid invoking #attributes, which builds a whole new hash per call.
      def attribute_method?(attr_name)
        keys.key?(attr_name) || !embedded_associations.detect {|a| a.name == attr_name }.nil?
      end

      private

      def write_key(key, value)
        key = unalias_key(key)
        if !keys.key?(key)
          super
        else
          attribute_will_change!(key) unless attribute_changed?(key)
          super.tap do
            changed_attributes.delete(key) unless attribute_value_changed?(key)
          end
        end
      end

      def attribute_value_changed?(key_name)
        changed_attributes[key_name] != read_key(key_name)
      end
    end
  end
end
