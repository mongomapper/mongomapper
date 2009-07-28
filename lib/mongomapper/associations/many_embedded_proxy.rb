module MongoMapper
  module Associations
    class ManyEmbeddedProxy < ArrayProxy
      def replace(v)
        @_values = v.map { |e| e.kind_of?(EmbeddedDocument) ? e.attributes : e }
        @target = nil

        reload_target
      end

      protected
        def find_target
          (@_values || []).map do |e|
            @association.klass.new(e)
          end
        end
    end
  end
end
