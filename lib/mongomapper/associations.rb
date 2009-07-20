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
          define_association_keys(association)
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
        
        def define_association_keys(association)
          if association.many?
            if association.polymorphic?
              association.klass.send :key, association.type_key_name, String
            end
          else
            key "#{association.name}_id", String
            
            if association.polymorphic?
              key association.type_key_name, String
            end
          end
        end
    end

    module InstanceMethods
      def get_proxy(association)
        unless proxy = self.instance_variable_get(association.ivar)
          proxy = association.proxy_class.new(self, association)
          self.instance_variable_set(association.ivar, proxy)
        end
        
        proxy
      end
    end
  end
end
