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

        define_association_methods(association, BelongsToProxy)

        self
      end

      def many(association_id, options = {})
        association = create_association(:many, association_id, options)
        proxy_class = HasManyProxy
        if association.klass.embeddable?
          proxy_class = HasManyEmbeddedProxy
        end

        define_association_methods(association, proxy_class)

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

      def define_association_methods(association, proxy_class)
        define_method(association.name) do
          get_proxy(association, proxy_class)
        end

        define_method("#{association.name}=") do |value|
          get_proxy(association, proxy_class).replace(value)
          value
        end
      end
    end

    module InstanceMethods
      private
      def get_proxy(association, klass)
        proxy = instance_variable_get(association.ivar)
        if proxy.nil?
          proxy = klass.new(self, association)
          instance_variable_set(association.ivar, proxy)
        end
        proxy
      end
    end
  end
end
