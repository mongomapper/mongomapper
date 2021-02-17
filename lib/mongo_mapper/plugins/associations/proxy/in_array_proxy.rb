# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class InArrayProxy < Collection
        include DynamicQuerying::ClassMethods

        def find(*args)
          order_results(query.find(*scoped_ids(args)))
        end

        def find!(*args)
          order_results(query.find!(*scoped_ids(args)))
        end

        def paginate(options)
          return [] if ids.blank?
          query.paginate(options)
        end

        def all(options={})
          return [] if ids.blank?
          order_results(query(options).all)
        end

        def first(options={})
          return nil if ids.blank?

          if ordered?
            ids = find_ordered_ids(options)
            find!(ids.first) if ids.any?
          else
            query(options).first
          end
        end

        def last(options={})
          return nil if ids.blank?

          if ordered?
            ids = find_ordered_ids(options)
            find!(ids.last) if ids.any?
          else
            query(options).last
          end
        end

        def count(options={})
          return 0 if ids.blank?
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
            ids << doc.id
            proxy_owner.save
            reset
          end
          doc
        end

        def create!(attrs={})
          doc = klass.create!(attrs)
          if doc.persisted?
            ids << doc.id
            proxy_owner.save
            reset
          end
          doc
        end

        def <<(*docs)
          flatten_deeper(docs).each do |doc|
            doc.save unless doc.persisted?
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
            doc.save unless doc.persisted?
            doc.id
          end
          ids.replace(doc_ids.uniq)
          reset
        end

      private

        def query(options={})
          klass.
            query(association.query_options).
            amend(options).
            amend(criteria)
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

        def find_ordered_ids(options={})
          return ids if options.empty?

          matched_ids = klass.collection.distinct(:_id, query(options).criteria.to_hash)
          matched_ids.sort_by! { |matched_id| ids.index(matched_id) }
        end

        def find_target
          return [] if ids.blank?
          all
        end

        def ids
          proxy_owner[options[:in]]
        end

        def order_results(objects)
          return objects if !ordered?
          return objects unless objects.respond_to?(:to_a) && objects.respond_to?(:sort_by)
          objects.sort_by { |obj| ids.index(obj.id) }
        end

        def ordered?
          association.ordered?
        end

      end
    end
  end
end
