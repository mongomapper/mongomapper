module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
      def replace(doc)
        if doc
          doc.save if doc.new?
          id = doc.id
        end

        @owner.send("#{@association.belongs_to_key_name}=", id)
        reset
      end

      protected
        def find_target
          if association_id = @owner.send(@association.belongs_to_key_name)
            @association.klass.find_by_id(association_id)
          end
        end
    end
  end
end
