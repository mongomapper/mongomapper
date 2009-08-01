module MongoMapper
  module Associations
    class ManyPolymorphicProxy < ManyDocumentsProxy      
      private
        def apply_scope(doc)
          doc.send("#{@association.type_key_name}=", doc.class.name)
          super
        end
    end
  end
end
