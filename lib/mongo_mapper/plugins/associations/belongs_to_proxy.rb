module MongoMapper
  module Plugins
    module Associations
      class BelongsToProxy < Proxy
        undef_method :object_id
        
        def replace(doc)
          if doc
            doc.save if doc.new?
            id = doc.id
          end

          owner[association.foreign_key] = id
          reset
        end

        protected
          def find_target
            return nil if owner[association.foreign_key].nil?
            klass.find_by_id(owner[association.foreign_key])
          end
      end
    end
  end
end
