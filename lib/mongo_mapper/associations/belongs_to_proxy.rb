module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
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
          klass.first(:id => owner[reflection.foreign_key])
        end
    end
  end
end
