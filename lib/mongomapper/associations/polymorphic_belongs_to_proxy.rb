module MongoMapper
  module Associations
    class PolymorphicBelongsToProxy < Proxy
      def replace(doc)        
        if doc
          doc.save if doc.new?
          id, type = doc.id, doc.class.name
        end
        
        @owner.send("#{@association.belongs_to_key_name}=", id)
        @owner.send("#{@association.type_key_name}=", type)
        
        reload_target
      end
      
      protected
        def find_target
          proxy_class.find(proxy_id) if proxy_id && proxy_class
        end
        
        def proxy_id
          @proxy_id ||= @owner.send(@association.belongs_to_key_name)
        end
        
        def proxy_class
          @proxy_class ||= begin
            klass = @owner.send(@association.type_key_name)
            klass && klass.constantize
          end
        end
    end
  end
end
