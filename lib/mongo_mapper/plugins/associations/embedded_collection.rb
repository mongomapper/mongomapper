# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class EmbeddedCollection < Collection
        def build(attributes={})
          doc = klass.new(attributes)
          assign_references(doc)
          self << doc
          doc
        end

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
            assign_references(doc)
            target << doc
          end
        end
        alias_method :push, :<<
        alias_method :concat, :<<

        def save_to_collection(options={})
          @target.each { |doc| doc.persist(options) } if @target
        end

        private
          def assign_references(*docs)
            docs.each { |doc| doc._parent_document = proxy_owner }
          end
      end
    end
  end
end