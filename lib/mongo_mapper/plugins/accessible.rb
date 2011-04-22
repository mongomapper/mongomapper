module MongoMapper
  module Plugins
    module Accessible
      extend ActiveSupport::Concern

      included do
        class_attribute :_attr_accessible
      end

      module ClassMethods
        def attr_accessible(*attrs)
          raise AccessibleOrProtected.new(name) if try(:protected_attributes?)
          self._attr_accessible = Set.new(attrs) + (accessible_attributes || [])
        end

        def accessible_attributes?
          !accessible_attributes.nil?
        end

        def accessible_attributes
          self._attr_accessible
        end
      end

      module InstanceMethods
        def assign(attrs={})
          super(filter_inaccessible_attrs(attrs))
        end

        def update_attributes(attrs={})
          super(filter_inaccessible_attrs(attrs))
        end

        def update_attributes!(attrs={})
          super(filter_inaccessible_attrs(attrs))
        end

        def accessible_attributes
          self.class.accessible_attributes
        end

        protected
          def filter_inaccessible_attrs(attrs)
            return attrs if accessible_attributes.blank? || attrs.blank?
            attrs.dup.delete_if { |key, val| !accessible_attributes.include?(key.to_sym) }
          end
      end
    end
  end
end