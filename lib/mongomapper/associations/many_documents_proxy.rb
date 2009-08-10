module MongoMapper
  module Associations
    class ManyDocumentsProxy < Proxy
      delegate :klass, :to => :@association

      def find(*args)
        options = args.extract_options!
        klass.find(*args << scoped_options(options))
      end

      def paginate(options)
        klass.paginate(scoped_options(options))
      end

      def all(options={})
        find(:all, scoped_options(options))
      end

      def first(options={})
        find(:first, scoped_options(options))
      end

      def last(options={})
        find(:last, scoped_options(options))
      end

      def count(conditions={})
        klass.count(conditions.deep_merge(scoped_conditions))
      end

      def replace(docs)
        @target.map(&:destroy) if load_target
        docs.each { |doc| apply_scope(doc).save }
        reset
      end

      def <<(*docs)
        ensure_owner_saved
        flatten_deeper(docs).each { |doc| apply_scope(doc).save }
        reset
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      def build(attrs={})
        doc = klass.new(attrs)
        apply_scope(doc)
        doc
      end

      def create(attrs={})
        doc = klass.new(attrs)
        apply_scope(doc).save
        doc
      end

      def destroy_all(conditions={})
        all(:conditions => conditions).map(&:destroy)
        reset
      end

      def delete_all(conditions={})
        klass.delete_all(conditions.deep_merge(scoped_conditions))
        reset
      end
      
      def nullify
        criteria = FinderOptions.to_mongo_criteria(scoped_conditions)
        all(criteria).each do |doc|
          doc.update_attributes self.foreign_key => nil
        end
        reset
      end

      protected
        def scoped_conditions
          {self.foreign_key => @owner.id}
        end

        def scoped_options(options)
          options.deep_merge({:conditions => scoped_conditions})
        end

        def find_target
          find(:all)
        end

        def ensure_owner_saved
          @owner.save if @owner.new?
        end

        def apply_scope(doc)
          ensure_owner_saved
          doc.send("#{self.foreign_key}=", @owner.id)
          doc
        end

        def foreign_key
          @association.options[:foreign_key] || @owner.class.name.underscore.gsub("/", "_") + "_id"
        end
    end
  end
end
