# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      extend ActiveSupport::Concern

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
          @associations ||= {}
        end

        def associations=(hash)
          @embedded_associations = nil
          @associations = hash
        end

        def embedded_associations
          @embedded_associations ||= associations.values.select { |assoc| assoc.embeddable? }
        end

        def associations_module_defined?
          if method(:const_defined?).arity == 1 # Ruby 1.9 compat check
            const_defined?('MongoMapperAssociations')
          else
            const_defined?('MongoMapperAssociations', false)
          end
        end

        def associations_module
          if associations_module_defined?
            const_get 'MongoMapperAssociations'
          else
            Module.new.tap do |m|
              const_set 'MongoMapperAssociations', m
              include m
            end
          end
        end

        private
          def create_association(association)
            @embedded_associations = nil
            associations[association.name] = association
            association.setup(self)
          end
      end

      def associations
        self.class.associations
      end

      def embedded_associations
        self.class.embedded_associations
      end

      def build_proxy(association)
        proxy = association.proxy_class.new(self, association)
        self.instance_variable_set(association.ivar, proxy)

        proxy
      end

      def get_proxy(association)
        proxy = self.instance_variable_get(association.ivar) if instance_variable_defined?(association.ivar)
        proxy ||= build_proxy(association)
      end

      def save_to_collection(options={})
        super if defined?(super)
        associations.each do |association_name, association|
          proxy = get_proxy(association)
          proxy.save_to_collection(options) if proxy.proxy_respond_to?(:save_to_collection) && association.autosave?
        end
      end
    end
  end
end
