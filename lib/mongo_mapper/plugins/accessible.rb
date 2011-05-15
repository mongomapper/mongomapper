module MongoMapper
  module Plugins
    module Accessible
      extend ActiveSupport::Concern

      included do
        class_attribute :accessible_attributes
      end

      module ClassMethods
        def attr_accessible(*attrs)
          raise AccessibleOrProtected.new(name) if try(:protected_attributes?)
          self.accessible_attributes = Set.new(attrs) + (accessible_attributes || [])
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

        protected
          def filter_inaccessible_attrs(attrs)
            return attrs if accessible_attributes.blank? || attrs.blank?
            attrs.dup.delete_if { |key, val| !accessible_attributes.include?(key.to_sym) }
          end
      end
    end
  end
end