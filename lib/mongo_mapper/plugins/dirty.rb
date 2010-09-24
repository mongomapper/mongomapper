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
          super.tap { clear_changes }
        end

        def save(*)
          if status = super
            clear_changes
          end
          status
        end

        def save!(*)
          status = super
          clear_changes
          status
        end

        def reload(*)
          document = super
          clear_changes
          document
        end

        protected

        def attribute_method?(attr)
          #This overrides ::ActiveSupport::Dirty#attribute_method? to allow attributes to be any key
          #in the attributes hash ( default ) or any key defined on the model that may not yet have
          #had a value stored in the attributes collection.
          super || key_names.include?(attr)
        end

        private

        def clear_changes
          @previously_changed = changes
          changed_attributes.clear
        end

        def write_key(key, value)
          key = key.to_s
          old = read_key(key)
          attribute_will_change!(key) if value_changed?(key,old,value)
          super(key, value)
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