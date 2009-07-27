module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
      def replace(doc)
        if doc
          doc.save if doc.new?
          id = doc.id
        end
        
        @owner.send("#{@association.belongs_to_key_name}=", id)
        reload_target
      end

      protected
        def find_target
          if ref = @owner.send(@association.belongs_to_key_name)
            @association.klass.find(ref)
          end
        end
    end
  end
end
