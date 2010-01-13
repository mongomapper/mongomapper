module MongoMapper
  module Plugins
    module Protected
      module ClassMethods
        def attr_protected( *attrs )
          self.write_inheritable_attribute( :attr_protected, Set.new(attrs) + (protected_attributes || []) )
        end
        def protected_attributes
          self.read_inheritable_attribute( :attr_protected )
        end
      end

      module InstanceMethods
        def update_attributes( attrs = {} )
          super filter_protected_attrs(attrs)
        end

        def update_attributes!( attrs = {} )
          super filter_protected_attrs(attrs)
        end

      protected
        def filter_protected_attrs( attrs )
          prot_attrs = self.class.protected_attributes
          return attrs  unless prot_attrs
          attrs.dup.delete_if { |key, val|  prot_attrs.include?(key) }
        end
      end
    end
  end
end
