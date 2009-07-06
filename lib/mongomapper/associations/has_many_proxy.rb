module MongoMapper
  module Associations
    class HasManyProxy < Proxy
      protected
      def find_target
        @association.klass.find(:all, {:conditions => {self.foreign_key => @owner.id}})
      end

      def foreign_key
        @association.options[:foreign_key] || @owner.class.name.underscore.gsub("/", "_") + "_id"
      end
    end
  end
end
