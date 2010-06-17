# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class InArrayProxy < Collection
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
          options.blank? ? ids.size : query(options).count
        end

        def destroy_all(options={})
          all(options).each do |doc|
            ids.delete(doc.id)
            doc.destroy
          end
          reset
        end

        def delete_all(options={})
          docs = query(options).fields(:_id).all
          docs.each { |doc| ids.delete(doc.id) }
          klass.delete(docs.map(&:id))
          reset
        end

        def nullify
          replace([])
          reset
        end

        def create(attrs={})
          doc = klass.create(attrs)
          unless doc.new?
            ids << doc.id
            proxy_owner.save
            reset
          end
          doc
        end

        def create!(attrs={})
          doc = klass.create!(attrs)
          unless doc.new?
            ids << doc.id
            proxy_owner.save
            reset
          end
          doc
        end

        def <<(*docs)
          flatten_deeper(docs).each do |doc|
            doc.save if doc.new?
            unless ids.include?(doc.id)
              ids << doc.id
            end
          end
          reset
        end
        alias_method :push, :<<
        alias_method :concat, :<<

        def replace(docs)
          doc_ids = docs.map do |doc|
            doc.save if doc.new?
            doc.id
          end
          ids.replace(doc_ids.uniq)
          reset
        end

        private
          def query(options={})
            klass.
              query(association.query_options).
              update(options).
              update(criteria)
          end

          def criteria
            {:_id => ids}
          end

          def scoped_ids(args)
            valid = args.flatten.select do |id|
              id = ObjectId.to_mongo(id) if klass.using_object_id?
              ids.include?(id)
            end
            valid.empty? ? nil : valid
          end

          def find_target
            ids.blank? ? [] : all
          end

          def ids
            proxy_owner[options[:in]]
          end
      end
    end
  end
end