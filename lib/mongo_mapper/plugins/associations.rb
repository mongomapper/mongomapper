# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      module ClassMethods
        def inherited(subclass)
          subclass.associations = associations.dup
          super
        end

        def belongs_to(association_id, options={}, &extension)
          create_association(BelongsToAssociation.new(association_id, options, &extension))
        end

        def many(association_id, options={}, &extension)
          create_association(ManyAssociation.new(association_id, options, &extension))
        end

        def one(association_id, options={}, &extension)
          create_association(OneAssociation.new(association_id, options, &extension))
        end

        def associations
          @associations ||= HashWithIndifferentAccess.new
        end

        def associations=(hash)
          @associations = hash
        end

        private
          def create_association(association)
            associations[association.name] = association
            association.setup(self)

            if association.one? || association.belongs_to?
              define_method(association.name) do
                proxy = get_proxy(association)
                proxy.nil? ? nil : proxy
              end

              define_method("#{association.name}=") do |value|
                proxy = get_proxy(association)

                if proxy.nil? || proxy.target != value
                  proxy = build_proxy(association)
                end

                proxy.replace(value)
                value
              end

              define_method("#{association.name}?") do
                get_proxy(association).present?
              end
            end
          end
      end

      module InstanceMethods
        def associations
          self.class.associations
        end

        def embedded_associations
          associations.select do |name, association|
            association.embeddable?
          end.map do |name, association|
            association
          end
        end

        def build_proxy(association)
          proxy = association.proxy_class.new(self, association)
          self.instance_variable_set(association.ivar, proxy)

          proxy
        end

        def get_proxy(association)
          unless proxy = self.instance_variable_get(association.ivar)
            proxy = build_proxy(association)
          end
          proxy
        end

        def save_to_collection(options={})
          super
          associations.each do |association_name, association|
            proxy = get_proxy(association)
            proxy.save_to_collection(options) if proxy.proxy_respond_to?(:save_to_collection)
          end
        end
      end
    end
  end
end
