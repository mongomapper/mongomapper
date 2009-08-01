module MongoMapper
  module Associations
    class ManyProxy < ManyArrayProxy
      def replace(docs)
        if load_target
          @target.map(&:destroy)
        end

        docs.each do |doc|
          @owner.save if @owner.new?
          doc.send(:write_attribute, self.foreign_key, @owner.id)
          doc.save
        end
        
        reload_target
      end
    end
  end
end
