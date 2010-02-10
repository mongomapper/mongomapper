module MongoMapper
  module Plugins
    module Associations
      module ClassMethods
        def belongs_to(association_id, options={}, &extension)
          create_association(:belongs_to, association_id, options, &extension)
        end

        def many(association_id, options={}, &extension)
          create_association(:many, association_id, options, &extension)
        end

        def one(association_id, options={}, &extension)
          create_association(:one, association_id, options, &extension)
        end

        def associations
          @associations ||= HashWithIndifferentAccess.new
        end

        def associations=(hash)
          @associations = hash
        end

        def inherited(subclass)
          subclass.associations = associations.dup
          super
        end

        private
          def create_association(type, name, options, &extension)
            association = Associations::Base.new(type, name, options, &extension)
            associations[association.name] = association

            define_method(association.name) do
              get_proxy(association)
            end

            define_method("#{association.name}=") do |value|
              get_proxy(association).replace(value)
              value
            end

            if association.one? || association.belongs_to?
              define_method("#{association.name}?") do
                get_proxy(association).present?
              end
            end

            if association.options[:dependent] && association.many? && !association.embeddable?
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
          end
      end

      module InstanceMethods
        def associations
          self.class.associations
        end

        # @api private?
        def embedded_associations
          associations.select do |name, association|
            association.embeddable?
          end.map do |name, association|
            association
          end
        end

        def get_proxy(association)
          unless proxy = self.instance_variable_get(association.ivar)
            proxy = association.proxy_class.new(self, association)
            self.instance_variable_set(association.ivar, proxy)
          end

          proxy
        end
      end

      autoload :Base,                         'mongo_mapper/plugins/associations/base'
      autoload :Collection,                   'mongo_mapper/plugins/associations/collection'
      autoload :EmbeddedCollection,           'mongo_mapper/plugins/associations/embedded_collection'
      autoload :ManyDocumentsProxy,           'mongo_mapper/plugins/associations/many_documents_proxy'
      autoload :BelongsToProxy,               'mongo_mapper/plugins/associations/belongs_to_proxy'
      autoload :BelongsToPolymorphicProxy,    'mongo_mapper/plugins/associations/belongs_to_polymorphic_proxy'
      autoload :ManyPolymorphicProxy,         'mongo_mapper/plugins/associations/many_polymorphic_proxy'
      autoload :ManyEmbeddedProxy,            'mongo_mapper/plugins/associations/many_embedded_proxy'
      autoload :ManyEmbeddedPolymorphicProxy, 'mongo_mapper/plugins/associations/many_embedded_polymorphic_proxy'
      autoload :ManyDocumentsAsProxy,         'mongo_mapper/plugins/associations/many_documents_as_proxy'
      autoload :OneProxy,                     'mongo_mapper/plugins/associations/one_proxy'
      autoload :InArrayProxy,                 'mongo_mapper/plugins/associations/in_array_proxy'
    end
  end
end

require 'mongo_mapper/plugins/associations/proxy'