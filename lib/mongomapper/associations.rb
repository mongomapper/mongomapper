module MongoMapper
  module Associations
    module ClassMethods
      def belongs_to(association_id, options = {})
        create_association(:belongs_to, association_id, options)
        self
      end

      def many(association_id, options = {})
        create_association(:many, association_id, options)
        self
      end

      def associations
        @associations ||= HashWithIndifferentAccess.new
      end

      private
        def create_association(type, name, options)
          association = Associations::Base.new(type, name, options)
          associations[association.name] = association
          define_association_methods(association)
          define_dependent_callback(association)
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

        def define_dependent_callback(association)
          if association.options[:dependent]
            if association.many?
              define_dependent_callback_for_many(association)
            elsif association.belongs_to?
              define_dependent_callback_for_belongs_to(association)
            end
          end
        end

        def define_dependent_callback_for_many(association)
          return if association.embeddable?

          after_destroy do |doc|
            case association.options[:dependent]
            when :destroy
              doc.get_proxy(association).destroy_all
            when :delete_all
              doc.get_proxy(association).delete_all
            when :nullify
              doc.get_proxy(association).nullify
            end
          end
        end

        def define_dependent_callback_for_belongs_to(association)
          after_destroy do |doc|
            case association.options[:dependent]
            when :destroy
              doc.get_proxy(association).destroy
            end
          end
        end
    end

    module InstanceMethods
      def get_proxy(association)
        unless proxy = self.instance_variable_get(association.ivar)
          proxy = association.proxy_class.new(self, association)
          self.instance_variable_set(association.ivar, proxy) if !frozen?
        end

        proxy
      end
    end
  end
end
