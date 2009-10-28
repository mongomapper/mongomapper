module MongoMapper
  module Associations
    module ClassMethods
      def belongs_to(association_id, options={})
        create_association(:belongs_to, association_id, options)
        self
      end

      def many(association_id, options = {}, &block)
        create_association(:many, association_id, options, &block)
        self
      end

      def associations
        @associations ||= self.superclass.respond_to?(:associations) ? 
                            self.superclass.associations : 
                            HashWithIndifferentAccess.new
      end

      private
        def create_association(type, name, options, &extension)
          options[:extend] = modulized_extensions(extension, options[:extend])
          association = Associations::Base.new(type, name, options)
          associations[association.name] = association
          define_association_methods(association)
          define_dependent_callback(association)
          association
        end
        
        def modulized_extensions(*extensions)
          extensions.flatten.compact.map do |extension|
            Proc === extension ? Module.new(&extension) : extension
          end
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
            end
          end
        end

        def define_dependent_callback_for_many(association)
          after_destroy do |doc|
            if !association.embeddable?
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
