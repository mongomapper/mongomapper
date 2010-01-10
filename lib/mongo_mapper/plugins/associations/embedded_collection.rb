module MongoMapper
  module Plugins
    module Associations
      class EmbeddedCollection < Collection
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

        def count
          load_target
          target.size
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
          def _root_document
            owner._root_document || owner
          end

          def assign_root_document(*docs)
            docs.each do |doc|
              doc._root_document = _root_document
            end
          end
      end
    end
  end
end