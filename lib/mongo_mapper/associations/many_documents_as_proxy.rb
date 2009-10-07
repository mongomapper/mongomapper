module MongoMapper
  module Associations
    class ManyDocumentsAsProxy < ManyDocumentsProxy
      protected
        def scoped_conditions
          {as_type_name => @owner.class.name, as_id_name => @owner.id}
        end

        def apply_scope(doc)
          ensure_owner_saved

          doc.send("#{as_type_name}=", @owner.class.name)
          doc.send("#{as_id_name}=", @owner.id)

          doc
        end

        def as_type_name
          @as_type_name ||= @association.options[:as].to_s + "_type"
        end

        def as_id_name
          @as_id_name ||= @association.options[:as].to_s + "_id"
        end
    end
  end
end
