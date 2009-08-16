module MongoMapper
  module Associations
    class BelongsToPolymorphicProxy < Proxy
      def replace(doc)        
        if doc
          doc.save if doc.new?
          id, type = doc.id, doc.class.name
        end
        
        @owner.send("#{@association.foreign_key}=", id)
        @owner.send("#{@association.type_key_name}=", type)
        reset
      end
      
      protected
        def find_target
          if proxy_id && proxy_class
            proxy_class.find_by_id(proxy_id)
          end
        end
        
        def proxy_id
          @proxy_id ||= @owner.send(@association.foreign_key)
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
