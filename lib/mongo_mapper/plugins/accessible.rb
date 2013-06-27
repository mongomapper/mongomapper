module MongoMapper
  module Plugins
    module Accessible
      extend ActiveSupport::Concern

      included do
        class_attribute :_accessible_attributes
      end

      module ClassMethods
        def attr_accessible(*attrs)
          raise AccessibleOrProtected.new(name) if try(:protected_attributes?)
          self._accessible_attributes = Set.new(attrs) + (_accessible_attributes || [])
        end

        def accessible_attributes(*)
          _accessible_attributes
        end

        def accessible_attributes?
          _accessible_attributes?
        end
      end

      def attributes=(attrs={})
        super(filter_inaccessible_attrs(attrs))
      end

      def assign_attributes(new_attributes, options={})
        self.attributes=(new_attributes)
      end

      def update_attributes(attrs={})
        super(filter_inaccessible_attrs(attrs))
      end

      def update_attributes!(attrs={})
        super(filter_inaccessible_attrs(attrs))
      end

      def accessible_attributes(*args)
        self.class.accessible_attributes(*args)
      end

      def accessible_attributes?
        self.class.accessible_attributes?
      end

    protected

      def filter_inaccessible_attrs(attrs)
        return attrs if !accessible_attributes? || attrs.blank?
        attrs.dup.delete_if { |key, val| attribute_inaccessible?(key.to_sym) }
      end

      def attribute_inaccessible?(attribute)
        unless accessible_attributes.include?(attribute)
          message = "Can't mass-assign protected attribute: #{attribute}"
          MongoMapper.logger ? MongoMapper.logger.warn(message) : puts(message)

          return true
        end
      end
    end
  end
end
