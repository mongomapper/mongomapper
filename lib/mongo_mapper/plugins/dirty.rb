# encoding: UTF-8
module MongoMapper
  module Plugins
    module Dirty
      def self.configure(model)
        model.class_eval do
          include ::ActiveModel::Dirty
        end
      end

      module InstanceMethods
        def initialize(*)
          # never register initial id assignment as a change
          super.tap { changed_attributes.delete('_id') }
        end

        def initialize_from_database(*)
          super.tap{clear_changes}
        end

        def save(*)
          try_clear_changes{super}
        end

        def save!(*)
          try_clear_changes{super}
        end

        def reload(*)
          super.tap{clear_changes}
        end

        protected

        def attribute_method?(attr)
          # This overrides ::ActiveSupport::Dirty#attribute_method? to allow attributes to be any key
          # in the attributes hash ( default ) or any key defined on the model that may not yet have
          # had a value stored in the attributes collection.
          super || key_names.include?(attr)
        end

        def try_clear_changes
          previous = changes
          (block_given? ? yield : true).tap do |result|
            unless result==false #failed validation; nil is OK.
              @previously_changed = previous
              changed_attributes.clear
            end
          end
        end
        alias clear_changes try_clear_changes

        private

        def write_key(key, value)
          key = key.to_s
          old = read_key(key)
          attribute_will_change!(key) if attribute_should_change?(key,old,value)
          changed_attributes.delete(key) unless value_changed?(key,attribute_was(key),value)
          super(key, value)
        end

        def attribute_should_change?(key,old,value)
          attribute_changed?(key) == false && value_changed?(key,old,value)
        end

        def value_changed?(key_name, old, value)
          key = keys[key_name]

          if key.number? && value.blank?
            value = nil
          end

          old != value
        end
      end
    end
  end
end