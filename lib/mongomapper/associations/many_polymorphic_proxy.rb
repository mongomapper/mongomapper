module MongoMapper
  module Associations
    class ManyPolymorphicProxy < ManyArrayProxy      
      def replace(docs)
        if load_target
          @target.map(&:destroy)
        end
        
        docs.each do |doc|
          @owner.save if @owner.new?
          doc.send("#{self.foreign_key}=", @owner.id)
          doc.send("#{@association.type_key_name}=", doc.class.name)
          doc.save
        end
        
        reload_target
      end
    end
  end
end
