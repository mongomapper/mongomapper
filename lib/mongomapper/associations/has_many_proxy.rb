module MongoMapper
  module Associations
    class HasManyProxy < ArrayProxy
      def replace(v)
        if load_target
          @target.map(&:destroy)
        end

        v.each do |o|
          @owner.save if @owner.new?
          o.__send__(:write_attribute, self.foreign_key, @owner.id)
          o.save
          o
        end
        
        reload_target
      end

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
