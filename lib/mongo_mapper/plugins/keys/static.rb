module MongoMapper
  module Plugins
    module Keys
      module Static
        class MissingKeyError < StandardError; end

        extend ActiveSupport::Concern

        included do
          self.static_keys = false
        end

        module ClassMethods
          attr_accessor :static_keys

          def embedded_keys
            @embedded_keys ||= embedded_associations.collect(&:as)
          end

          def embedded_key?(key)
            embedded_keys.include?(key.to_sym)
          end
        end

        def read_key(name)
          if !self.class.static_keys || self.class.key?(name)
            super
          else
            raise MissingKeyError, "Tried to read the key #{name.inspect}, but no key was defined. Either define key :#{name} or set self.static_keys = false"
          end
        end

      private

        def write_key(name, value)
          if !self.class.static_keys || self.class.key?(name)
            super
          else
            raise MissingKeyError, "Tried to write the key #{name.inspect}, but no key was defined. Either define key :#{name} or set self.static_keys = false"
          end
        end

        def load_from_database(attrs, with_cast = false)
          return super if !self.class.static_keys || !attrs.respond_to?(:each)

          attrs = attrs.select { |key, _| self.class.key?(key) || self.class.embedded_key?(key) }

          super(attrs, with_cast)
        end
      end
    end
  end
end
