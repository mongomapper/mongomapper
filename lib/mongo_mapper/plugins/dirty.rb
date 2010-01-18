module MongoMapper
  module Plugins
    module Dirty
      module InstanceMethods
        def method_missing(method, *args, &block)
          if method.to_s =~ /(_changed\?|_change|_will_change!|_was)$/
            method_suffix = $1
            key = method.to_s.gsub(method_suffix, '')

            if key_names.include?(key)
              case method_suffix
                when '_changed?'
                  key_changed?(key)
                when '_change'
                  key_change(key)
                when '_will_change!'
                  key_will_change!(key)
                when '_was'
                  key_was(key)
              end
            else
              super
            end
          else
            super
          end
        end

        def changed?
          !changed_keys.empty?
        end

        def changed
          changed_keys.keys
        end

        def changes
          changed.inject({}) { |h, key| h[key] = key_change(key); h }
        end

        def initialize(*args)
          super
          changed_keys.clear if args.first.blank? || !new?
        end

        def save(*args)
          if status = super
            changed_keys.clear
          end
          status
        end

        def save!(*args)
          status = super
          changed_keys.clear
          status
        end

        def reload(*args)
          document = super
          changed_keys.clear
          document
        end

        private
          def clone_key_value(key)
            value = read_key(key)
            value.duplicable? ? value.clone : value
          rescue TypeError, NoMethodError
            value
          end

          def changed_keys
            @changed_keys ||= {}
          end

          def key_changed?(key)
            changed_keys.include?(key)
          end

          def key_change(key)
            [changed_keys[key], __send__(key)] if key_changed?(key)
          end

          def key_was(key)
            key_changed?(key) ? changed_keys[key] : __send__(key)
          end

          def key_will_change!(key)
            changed_keys[key] = clone_key_value(key)
          end

          def write_key(key, value)
            key = key.to_s

            if changed_keys.include?(key)
              old = changed_keys[key]
              changed_keys.delete(key) unless value_changed?(key, old, value)
            else
              old = clone_key_value(key)
              changed_keys[key] = old if value_changed?(key, old, value)
            end

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