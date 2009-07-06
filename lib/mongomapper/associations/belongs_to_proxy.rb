module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
      protected
      def find_target
        ref = @owner.send(:read_attribute, "#{@association.name}_id")
        if ref
          @association.klass.find(ref)
        end
      end
    end
  end
end
