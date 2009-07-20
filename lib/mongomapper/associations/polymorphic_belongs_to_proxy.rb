module MongoMapper
  module Associations
    class PolymorphicBelongsToProxy < Proxy
      def replace(v)
        ref_id = "#{@association.name}_id"
        ref_type = "#{@association.name}_type"

        if v
          v.save if v.new?
          @owner.__send__(:write_attribute, ref_id, v.id)
          @owner.__send__(:write_attribute, ref_type, v.class.name)
        else
          @owner.__send__(:write_attribute, ref_id, nil)
          @owner.__send__(:write_attribute, ref_type, nil)
        end
        @owner.save

        reload_target
      end

      protected
        def find_target
          ref_id = @owner.__send__(:read_attribute, "#{@association.name}_id")
          ref_type = @owner.__send__(:read_attribute, "#{@association.name}_type")
          if ref_id && ref_type
            ref_type.constantize.find(ref_id)
          end
        end
    end
  end
end
