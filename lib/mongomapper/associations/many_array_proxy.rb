module MongoMapper
  module Associations
    class ManyArrayProxy < Proxy
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
