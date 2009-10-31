module MongoMapper
  module Associations
    class ManyDocumentsProxy < Proxy
      delegate :klass, :to => :@association
      delegate :collection, :to => :klass
      
      include ::MongoMapper::Finders
      
      def find(*args)
        options = args.extract_options!
        klass.find(*args << scoped_options(options))
      end
      
      def find!(*args)
        options = args.extract_options!
        klass.find!(*args << scoped_options(options))
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
        klass.count(scoped_options(options))
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
      
      def create!(attrs={})
        doc = klass.new(attrs)
        apply_scope(doc).save!
        doc
      end

      def destroy_all(options={})
        all(options).map(&:destroy)
        reset
      end

      def delete_all(options={})
        klass.delete_all(options.merge(scoped_conditions))
        reset
      end
      
      def nullify
        criteria = FinderOptions.new(klass, scoped_conditions).criteria
        all(criteria).each do |doc|
          doc.update_attributes(self.foreign_key => nil)
        end
        reset
      end
      
      def method_missing(method, *args)
        finder = DynamicFinder.new(method)
        
        if finder.found?
          dynamic_find(finder, args)
        else
          super
        end
      end
      
      protected
        def scoped_conditions
          {self.foreign_key => @owner.id}
        end
        
        def scoped_options(options)
          @association.finder_options.merge(options).merge(scoped_conditions)
        end

        def find_target
          all
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
