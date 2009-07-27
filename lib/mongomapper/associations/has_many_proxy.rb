module MongoMapper
  module Associations
    class HasManyProxy < ArrayProxy
      delegate :klass, :to => :@association
      
      def find(*args)
        options = args.extract_options!
        klass.find(*args << scoped_options(options))
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
      
      def replace(docs)
        if load_target
          @target.map(&:destroy)
        end

        docs.each do |doc|
          @owner.save if @owner.new?
          doc.send(:write_attribute, self.foreign_key, @owner.id)
          doc.save
        end
        
        reload_target
      end

      protected
        def scoped_options(options)
          options.dup.deep_merge({:conditions => {self.foreign_key => @owner.id}})
        end
        
        def find_target
          find(:all)
        end

        def foreign_key
          @association.options[:foreign_key] || @owner.class.name.underscore.gsub("/", "_") + "_id"
        end
    end
  end
end
