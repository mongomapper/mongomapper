module MongoMapper
  module Associations
    class ManyEmbeddedProxy < Proxy
      def replace(v)
        @_values = v.map { |e| e.kind_of?(EmbeddedDocument) ? e.attributes : e }
        reset
      end

      def build(attributes={})
        doc = @association.klass.new(attributes)
        assign_root_document(doc)
        self << doc
        doc
      end

      def find(id)
        load_target
        @target.detect { |item| item.id == id }
      end

      def <<(*docs)
        if load_target
          docs.each do |doc|
            assign_root_document(doc)
            @target << doc
          end
        end
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      private
        def find_target
          (@_values || []).map do |e|
            child = @association.klass.new(e)
            assign_root_document(child)
            child
          end
        end

        def root_document
          @owner._root_document || @owner
        end

        def assign_root_document(*docs)
          docs.each do |doc|
            doc._root_document = root_document
          end
        end
    end
  end
end
