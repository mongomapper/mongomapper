module MongoMapper
  module Associations
    module ClassMethods
      def many(association_name, options = {})
        association = Associations::Base.new(:many, association_name.to_s.singularize, options)
        associations[association.name] = association

        class_eval <<-EOS
          def #{association.name}
            #{association.ivar} ||= []
            #{association.ivar}
          end
        EOS
      end

      def belongs_to(association_id, options = {})
        association = Associations::Base.new(:belongs_to, association_id, options)
        associations[association.name] = association

        ref_id = "#{association_id}_id"
        key ref_id, String

        define_method("#{ref_id}=") do |value|
          write_attribute(ref_id, value)
        end

        define_method(association_id) do |*params|
          ref = read_attribute(ref_id)
          if ref
            association.klass.find(ref)
          end
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
        association = Associations::Base.new(:has_many, association_id.to_s.singularize, options)
        associations[association.name] = association

        fk = options[:foreign_key] || self.name.underscore.gsub("/", "_") + "_id"

        define_method(association_id) do
          association.klass.find(:all, {:conditions => {fk => self.id}})
        end
      end

      def associations
        @associations ||= HashWithIndifferentAccess.new
      end
    end
  end
end
