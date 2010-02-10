module MongoMapper
  module Plugins
    module Associations
      class InArrayProxy < Collection
        include Support::Find

        def find(*args)
          options = args.extract_options!

          case args.first
            when :first
              first(options)
            when :last
              last(options)
            when :all
              all(options)
            else
              klass.find(*scoped_ids(args) << scoped_options(options))
          end
        end

        def find!(*args)
          options = args.extract_options!

          case args.first
            when :first
              first(options)
            when :last
              last(options)
            when :all
              all(options)
            else
              klass.find!(*scoped_ids(args) << scoped_options(options))
          end
        end

        def paginate(options)
          klass.paginate(scoped_options(options))
        end

        def all(options={})
          klass.all(scoped_options(options))
        end

        def first(options={})
          klass.first(scoped_options(options))
        end

        def last(options={})
          klass.last(scoped_options(options))
        end

        def count(options={})
          options.blank? ? ids.size : klass.count(scoped_options(options))
        end

        def destroy_all(options={})
          all(options).each do |doc|
            ids.delete(doc.id)
            doc.destroy
          end
          reset
        end

        def delete_all(options={})
          docs = all(options.merge(:select => ['_id']))
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
            owner.save
          end
          doc
        end

        def create!(attrs={})
          doc = klass.create!(attrs)
          unless doc.new?
            ids << doc.id
            owner.save
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
          def scoped_conditions
            {:_id => ids}
          end

          def scoped_options(options)
            association.query_options.merge(options).merge(scoped_conditions)
          end

          def scoped_ids(args)
            args.flatten.reject { |id| !ids.include?(id) }
          end

          def find_target
            ids.blank? ? [] : all
          end

          def ids
            owner[options[:in]]
          end
      end
    end
  end
end