module MongoMapper
  module Associations
    class HasManyEmbeddedProxy < ArrayProxy
      def replace(v)
        @association.value = v.map { |e| e.kind_of?(EmbeddedDocument) ? e.attributes : e }
        @target = nil

        load_target
        @owner.save
      end

      protected
      def find_target
        (@association.value || []).map do |e|
          @association.klass.new(e)
        end
      end
    end
  end
end
