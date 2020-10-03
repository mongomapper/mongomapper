# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class InForeignArrayProxy < Collection
        include DynamicQuerying::ClassMethods

        def find(*args)
          query.find(*scoped_ids(args))
        end

        def find!(*args)
          query.find!(*scoped_ids(args))
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

        def destroy_all(options={})
          all(options).each do |doc|
            doc.destroy
          end
          reset
        end

        def delete_all(options={})
          docs = query(options).fields(:_id).all
          klass.delete(docs.map { |d| d.id })
          reset
        end

        def nullify
          replace([])
          reset
        end

        def create(attrs={})
          doc = klass.create(attrs)
          if doc.persisted?
            inverse_association(doc) << proxy_owner
            doc.save
            reset
          end
          doc
        end

        def create!(attrs={})
          doc = klass.create!(attrs)

          if doc.persisted?
            inverse_association(doc) << proxy_owner
            doc.save
            reset
          end
          doc
        end

        def <<(*docs)
          flatten_deeper(docs).each do |doc|
            inverse_association(doc) << proxy_owner
            doc.save
          end
          reset
        end
        alias_method :push, :<<
        alias_method :concat, :<<

        def replace(docs)
          doc_ids = docs.map do |doc|
            doc.save unless doc.persisted?
            inverse_association(doc) << proxy_owner
            doc.save
            doc.id
          end

          replace_selector =  { options[:in_foreign] => proxy_owner.id }
          unless doc_ids.empty?
            replace_selector[:_id] = {"$not" => {"$in" => doc_ids}}
          end

          klass.collection.update_many(replace_selector, {
            "$pull" => { options[:in_foreign] => proxy_owner.id }
          })

          reset
        end

        private

          def query(options={})
            klass.query({}.merge(association.query_options, options, criteria))
          end

          def criteria
            {options[:in_foreign] => proxy_owner.id}
          end

          def scoped_ids(args)
            valid = args.flatten.map do |id|
              id = ObjectId.to_mongo(id) if klass.using_object_id?
              id
            end
            valid.empty? ? nil : valid
          end

          def find_target
            all
          end

          def inverse_association(doc)
            doc.send(options[:as].to_s.pluralize)
          end
      end
    end
  end
end
