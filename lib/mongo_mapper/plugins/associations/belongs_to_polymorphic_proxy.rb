module MongoMapper
  module Plugins
    module Associations
      class BelongsToPolymorphicProxy < Proxy
        undef_method :object_id
        
        def replace(doc)
          if doc
            doc.save if doc.new?
            id, type = doc.id, doc.class.name
          end

          owner[association.foreign_key] = id
          owner[association.type_key_name] = type
          reset
        end

        protected
          def find_target
            return nil if association_class.nil? || owner[association.foreign_key].nil?
            association_class.find_by_id(owner[association.foreign_key])
          end

          def association_class
            proxy_owner[association.type_key_name] ? proxy_owner[association.type_key_name].constantize : nil
          end
      end
    end
  end
end
