module MongoMapper
  module Plugins
    module Associations
      class ManyDocumentsAsProxy < ManyDocumentsProxy
        protected
          def scoped_conditions
            {type_key_name => owner.class.name, id_key_name => owner.id}
          end

          def apply_scope(doc)
            ensure_owner_saved
            doc[type_key_name] = owner.class.name
            doc[id_key_name] = owner.id
            doc
          end

        private
          def type_key_name
            "#{options[:as]}_type"
          end

          def id_key_name
            "#{options[:as]}_id"
          end
      end
    end
  end
end
