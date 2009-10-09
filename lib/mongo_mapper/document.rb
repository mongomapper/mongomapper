require 'set'

module MongoMapper
  module Document
    def self.included(model)
      model.class_eval do
        include EmbeddedDocument
        include InstanceMethods
        include Observing
        include Callbacks
        include SaveWithValidation
        include Dirty
        include RailsCompatibility::Document
        extend Validations::Macros
        extend ClassMethods
        extend Finders
        
        def self.per_page
          25
        end unless respond_to?(:per_page)
      end
      
      descendants << model
    end

    def self.descendants
      @descendants ||= Set.new
    end

    module ClassMethods
      def find(*args)
        options = args.extract_options!
        case args.first
          when :first then first(options)
          when :last  then last(options)
          when :all   then find_every(options)
          when Array  then find_some(args, options)
          else
            case args.size
              when 0
                raise DocumentNotFound, "Couldn't find without an ID"
              when 1
                find_one(args[0], options)
              else
                find_some(args, options)
            end
        end
      end

      def paginate(options)
        per_page      = options.delete(:per_page) ||  self.per_page
        page          = options.delete(:page)
        total_entries = count(options[:conditions] || {})
        collection    = Pagination::PaginationProxy.new(total_entries, page, per_page)

        options[:limit] = collection.limit
        options[:skip]  = collection.skip

        collection.subject = find_every(options)
        collection
      end

      def first(options={})
        options.merge!(:limit => 1)
        find_every(options)[0]
      end

      def last(options={})
        if options[:order].blank?
          raise ':order option must be provided when using last'
        end
        
        options.merge!(:limit => 1)
        options[:order] = invert_order_clause(options[:order])
        find_every(options)[0]
      end

      def all(options={})
        find_every(options)
      end

      def find_by_id(id)
        criteria = FinderOptions.to_mongo_criteria(:_id => id)
        if doc = collection.find_one(criteria)
          new(doc)
        end
      end

      def count(conditions={})
        collection.find(FinderOptions.to_mongo_criteria(conditions)).count
      end

      def create(*docs)
        instances = []
        docs = [{}] if docs.blank?
        docs.flatten.each do |attrs|
          doc = new(attrs); doc.save
          instances << doc
        end
        instances.size == 1 ? instances[0] : instances
      end

      # For updating single document
      #   Person.update(1, {:foo => 'bar'})
      #
      # For updating multiple documents at once:
      #   Person.update({'1' => {:foo => 'bar'}, '2' => {:baz => 'wick'}})
      def update(*args)
        updating_multiple = args.length == 1
        if updating_multiple
          update_multiple(args[0])
        else
          id, attributes = args
          update_single(id, attributes)
        end
      end

      def delete(*ids)
        criteria = FinderOptions.to_mongo_criteria(:_id => ids.flatten)
        collection.remove(criteria)
      end

      def delete_all(conditions={})
        criteria = FinderOptions.to_mongo_criteria(conditions)
        collection.remove(criteria)
      end

      def destroy(*ids)
        find_some(ids.flatten).each(&:destroy)
      end

      def destroy_all(conditions={})
        find(:all, :conditions => conditions).each(&:destroy)
      end

      def connection(mongo_connection=nil)
        if mongo_connection.nil?
          @connection ||= MongoMapper.connection
        else
          @connection = mongo_connection
        end
        @connection
      end

      def database(name=nil)
        if name.nil?
          @database ||= MongoMapper.database
        else
          @database = connection.db(name)
        end
        @database
      end
      
      # Changes the collection name from the default to whatever you want
      def set_collection_name(name=nil)
        @collection = nil
        @collection_name = name
      end
      
      # Returns the collection name, if not set, defaults to class name tableized
      def collection_name
        @collection_name ||= self.to_s.demodulize.tableize
      end

      # Returns the mongo ruby driver collection object
      def collection
        @collection ||= database.collection(collection_name)
      end
      
      def timestamps!
        key :created_at, Time
        key :updated_at, Time
        
        class_eval { before_save :update_timestamps }
      end
      
      protected
        def method_missing(method, *args)
          finder = DynamicFinder.new(method)
          
          if finder.found?
            meta_def(finder.method) { |*args| dynamic_find(finder, args) }
            send(finder.method, *args)
          else
            super
          end
        end

      private
        def find_every(options)
          criteria, options = FinderOptions.new(options).to_a
          collection.find(criteria, options).to_a.map { |doc| new(doc) }
        end

        def invert_order_clause(order)
          order.split(',').map do |order_segment| 
            if order_segment =~ /\sasc/i
              order_segment.sub /\sasc/i, ' desc'
            elsif order_segment =~ /\sdesc/i
              order_segment.sub /\sdesc/i, ' asc'
            else
              "#{order_segment.strip} desc"
            end
          end.join(',')
        end

        def find_some(ids, options={})
          ids = ids.flatten.compact.uniq
          documents = find_every(options.deep_merge(:conditions => {'_id' => ids}))
          
          if ids.size == documents.size
            documents
          else
            raise DocumentNotFound, "Couldn't find all of the ids (#{ids.to_sentence}). Found #{documents.size}, but was expecting #{ids.size}"
          end
        end

        def find_one(id, options={})
          if doc = find_every(options.deep_merge(:conditions => {:_id => id})).first
            doc
          else
            raise DocumentNotFound, "Document with id of #{id} does not exist in collection named #{collection.name}"
          end
        end

        def update_single(id, attrs)
          if id.blank? || attrs.blank? || !attrs.is_a?(Hash)
            raise ArgumentError, "Updating a single document requires an id and a hash of attributes"
          end

          doc = find(id)
          doc.update_attributes(attrs)
          doc
        end

        def update_multiple(docs)
          unless docs.is_a?(Hash)
            raise ArgumentError, "Updating multiple documents takes 1 argument and it must be hash"
          end

          instances = []
          docs.each_pair { |id, attrs| instances << update(id, attrs) }
          instances
        end
    end

    module InstanceMethods
      def collection
        self.class.collection
      end

      def new?
        read_attribute('_id').blank? || using_custom_id?
      end

      def save
        create_or_update
      end

      def save!
        create_or_update || raise(DocumentNotValid.new(self))
      end

      def destroy
        return false if frozen?

        criteria = FinderOptions.to_mongo_criteria(:_id => id)
        collection.remove(criteria) unless new?
        freeze
      end

    private
      def create_or_update
        result = new? ? create : update
        result != false
      end

      def create
        assign_id
        save_to_collection
      end
      
      def assign_id
        if read_attribute(:_id).blank?
          write_attribute(:_id, Mongo::ObjectID.new.to_s)
        end
      end

      def update
        save_to_collection
      end

      def save_to_collection
        clear_custom_id_flag
        collection.save(to_mongo)
      end

      def update_timestamps
        now = Time.now.utc
        write_attribute('created_at', now) if new?
        write_attribute('updated_at', now)
      end
      
      def clear_custom_id_flag
        @using_custom_id = nil
      end
    end
  end # Document
end # MongoMapper
