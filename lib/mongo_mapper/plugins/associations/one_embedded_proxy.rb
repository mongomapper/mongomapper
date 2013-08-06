# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class OneEmbeddedProxy < Proxy
        def build(attributes={})
          @target = klass.new(attributes)
          assign_references(@target)
          loaded
          @target
        end

        def replace(doc)
          if doc.respond_to?(:attributes)
            @target = klass.load(doc.attributes, true)
          else
            @target = klass.load(doc, true)
          end
          assign_references(@target)
          loaded
          @target
        end

        def save_to_collection(options={})
          @target.persist(options) if @target
        end

        protected

          def find_target
            if @value
              klass.load(@value, true).tap do |child|
                assign_references(child)
              end
            end
          end

          def assign_references(doc)
            doc._parent_document = proxy_owner if doc
          end
      end
    end
  end
end
