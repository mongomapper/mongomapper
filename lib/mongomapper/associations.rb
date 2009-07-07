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

        define_method(association_id) do |*params|
          get_proxy(association, BelongsToProxy)
        end

        define_method("#{association_id}=") do |value|
          if value
            write_attribute(ref_id, value.id)
          else
            write_attribute(ref_id, nil)
          end
          value
        end
      end

      def many(association_id, options = {})
        association = create_association(:many, association_id, options)

        define_method(association_id) do
          if association.klass.embeddable?
            get_proxy(association, HasManyEmbeddedProxy)
          else
            get_proxy(association, HasManyProxy)
          end
        end

        define_method("#{association_id}=") do |value|
          association.value = value
        end
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
