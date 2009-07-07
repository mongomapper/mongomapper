module MongoMapper
  module Associations
    module ClassMethods
      def belongs_to(association_id, options = {})
        association = create_association(:belongs_to, association_id, options)

        ref_id = "#{association_id}_id"
        key ref_id, String

        define_method("#{ref_id}=") do |value|
          write_attribute(ref_id, value)
        end

        if options[:polymorphic]
          ref_type = "#{association_id}_type"
          key ref_type, String

          define_method("#{ref_type}=") do |value|
            write_attribute(ref_type, value)
          end
        end

        define_association_methods(association)

        self
      end

      def many(association_id, options = {})
        association = create_association(:many, association_id, options)
        define_association_methods(association)

        self
      end

      def associations
        @associations ||= HashWithIndifferentAccess.new
      end

      private
      def create_association(type, name, options)
        association = Associations::Base.new(type, name, options)
        associations[association.name] = association
        association
      end

      def define_association_methods(association)
        define_method(association.name) do
          get_proxy(association)
        end

        define_method("#{association.name}=") do |value|
          get_proxy(association).replace(value)
          value
        end
      end
    end

    module InstanceMethods
      def get_proxy(association)
        proxy = self.instance_variable_get(association.ivar)
        if proxy.nil?
          proxy = association.proxy_class.new(self, association)
          self.instance_variable_set(association.ivar, proxy)
        end
        proxy
      end
    end
  end
end
