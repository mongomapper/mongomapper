module MongoMapper
  module Associations
    class BelongsToProxy < Proxy
      def replace(v)
        ref_id = "#{@association.name}_id"

        if v
          v.save if v.new?
          @owner.__send__(:write_attribute, ref_id, v.id)
        else
          @owner.__send__(:write_attribute, ref_id, nil)
        end
        @owner.save

        @target = nil
      end

      protected
      def find_target
        ref = @owner.__send__(:read_attribute, "#{@association.name}_id")
        if ref
          @association.klass.find(ref)
        end
      end
    end
  end
end
