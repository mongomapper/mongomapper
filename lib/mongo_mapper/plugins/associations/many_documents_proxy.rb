# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyDocumentsProxy < Collection
        include DynamicQuerying::ClassMethods

        def find(*args)
          query.find(*args)
        end

        def find!(*args)
          query.find!(*args)
        end

        def paginate(options)
          query.paginate(options)
        end

        def all(options={})
          query(options).all
        end

        def first(options={})
          query(options).first
        end

        def last(options={})
          query(options).last
        end

        def count(options={})
          query(options).count
        end

        def replace(docs)
          load_target
          target.map(&:destroy)
          docs.each { |doc| prepare(doc).save }
          reset
        end

        def <<(*docs)
          ensure_owner_saved
          flatten_deeper(docs).each { |doc| prepare(doc).save }
          reset
        end
        alias_method :push, :<<
        alias_method :concat, :<<

        def build(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc)
          @target ||= [] unless loaded?
          @target << doc
          doc
        end

        def create(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc).save
          reset
          doc
        end

        def create!(attrs={})
          doc = klass.new(attrs)
          apply_scope(doc).save!
          reset
          doc
        end

        def destroy_all(options={})
          all(options).map(&:destroy)
          reset
        end

        def delete_all(options={})
          query(options).remove
          reset
        end

        def nullify
          all.each { |doc| doc.update_attributes(self.foreign_key => nil) }
          reset
        end

        def save_to_collection(options={})
          @target.each { |doc| doc.save(options) } if @target
        end

        protected
          def query(options={})
            klass.
              query(association.query_options).
              update(options).
              update(criteria)
          end

          def criteria
            {self.foreign_key => proxy_owner.id}
          end

          def find_target
            all
          end

          def ensure_owner_saved
            proxy_owner.save if proxy_owner.new?
          end

          def prepare(doc)
            klass === doc ? apply_scope(doc) : build(doc)
          end

          def apply_scope(doc)
            ensure_owner_saved
            criteria.each { |key, value| doc[key] = value }
            doc
          end

          def foreign_key
            options[:foreign_key] || proxy_owner.class.name.to_s.underscore.gsub("/", "_") + "_id"
          end
      end
    end
  end
end
