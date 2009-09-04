module MongoMapper
  module Associations
    class ManyEmbeddedProxy < Proxy
      def replace(v)
        @_values = v.map { |e| e.kind_of?(EmbeddedDocument) ? e.attributes : e }
        reset
      end

      def <<(*docs)
        if load_target
          parent = @owner._parent_document || @owner
          docs.each do |doc|
            doc._parent_document = parent
            @target << doc
          end
        end
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      protected
        def find_target
          (@_values || []).map do |e|
            @association.klass.new(e)
          end
        end
    end
  end
end
