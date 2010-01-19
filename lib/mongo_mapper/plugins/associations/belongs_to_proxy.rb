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

          owner[reflection.foreign_key] = id
          reset
        end

        protected
          def find_target
            return nil if owner[reflection.foreign_key].nil?
            klass.find_by_id(owner[reflection.foreign_key])
          end
      end
    end
  end
end
