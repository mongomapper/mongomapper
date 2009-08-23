module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
      def replace(doc)
        if doc
          doc.save if doc.new?
          id = doc.id
        end

        @owner.send("#{@association.foreign_key}=", id)
        reset
      end

      protected
        def find_target
          if association_id = @owner.send(@association.foreign_key)
            @association.klass.find_by_id(association_id)
          end
        end
    end
  end
end
