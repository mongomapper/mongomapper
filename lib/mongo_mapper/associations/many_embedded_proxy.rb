module MongoMapper
  module Associations
    class ManyEmbeddedProxy < Collection
      def replace(values)
        @_values = values.map do |v|
          v.kind_of?(EmbeddedDocument) ? v.attributes : v
        end
        reset
      end

      def build(attributes={})
        doc = klass.new(attributes)
        assign_root_document(doc)
        self << doc
        doc
      end

      # TODO: test that both string and oid version work
      def find(id)
        load_target
        target.detect { |item| item.id.to_s == id || item.id == id }
      end

      def <<(*docs)
        load_target
        docs.each do |doc|
          assign_root_document(doc)
          target << doc
        end
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      private
        def find_target
          (@_values || []).map do |v|
            child = klass.new(v)
            assign_root_document(child)
            child
          end
        end

        def root_document
          owner._root_document || owner
        end

        def assign_root_document(*docs)
          docs.each do |doc|
            doc._root_document = root_document
          end
        end
    end
  end
end
