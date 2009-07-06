module MongoMapper
  module Associations
    module ClassMethods
      def many(association_name, options = {})
        association = create_association(:many, association_name.to_s.singularize, options)

        class_eval <<-EOS
          def #{association.name}
            #{association.ivar} ||= []
            #{association.ivar}
          end
        EOS
      end

      def belongs_to(association_id, options = {})
        association = create_association(:belongs_to, association_id, options)

        ref_id = "#{association_id}_id"
        key ref_id, String

        define_method("#{ref_id}=") do |value|
          write_attribute(ref_id, value)
        end

        define_method(association_id) do |*params|
          proxy = instance_variable_get(association.ivar)
          if proxy.nil?
            proxy = BelongsToProxy.new(self, association)
            instance_variable_set(association.ivar, proxy)
          end
          proxy
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

      def has_many(association_id, options = {})
        association = create_association(:has_many, association_id.to_s.singularize, options)

        fk = options[:foreign_key] || self.name.underscore.gsub("/", "_") + "_id"

        define_method(association_id) do
          association.klass.find(:all, {:conditions => {fk => self.id}})
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
  end
end
