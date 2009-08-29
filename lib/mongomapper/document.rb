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
        include RailsCompatibility::Document
        extend ClassMethods
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
          when :first then find_first(options)
          when :last  then find_last(options)
          when :all   then find_every(options)
          else             find_from_ids(args, options)
        end
      end

      def paginate(options)
        per_page      = options.delete(:per_page)
        page          = options.delete(:page)
        total_entries = count(options[:conditions] || {})
        collection    = Pagination::PaginationProxy.new(total_entries, page, per_page)

        options[:limit]   = collection.limit
        options[:offset]  = collection.offset

        collection.subject = find_every(options)
        collection
      end

      def first(options={})
        find_first(options)
      end

      def last(options={})
        find_last(options)
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

      def collection(name=nil)
        if name.nil?
          @collection ||= database.collection(self.to_s.demodulize.tableize)
        else
          @collection = database.collection(name)
        end
        @collection
      end
      
      def timestamps!
        key :created_at, Time
        key :updated_at, Time
        
        class_eval { before_save :update_timestamps }
      end
      
      def validates_uniqueness_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesUniquenessOf)
      end

      def validates_exclusion_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesExclusionOf)
      end

      def validates_inclusion_of(*args)
        add_validations(args, MongoMapper::Validations::ValidatesInclusionOf)
      end
      
      protected
        def method_missing(method, *args)
          finder = DynamicFinder.new(self, method)
          
          if finder.valid?
            meta_def(finder.options[:method]) do |*args|
              find_with_args(args, finder.options)
            end
            
            send(finder.options[:method], *args)
          else
            super
          end
        end

      private
        def find_every(options)
          criteria, options = FinderOptions.new(options).to_a
          collection.find(criteria, options).to_a.map { |doc| new(doc) }
        end

        def find_first(options)
          options.merge!(:limit => 1)
          find_every({:order => '$natural asc'}.merge(options))[0]
        end

        def find_last(options)
          options.merge!(:limit => 1)
          options[:order] = invert_order_clause(options)
          find_every(options)[0]
          #find_every({:order => '$natural desc'}.merge(invert_order_clause(options)))[0]
        end

        def invert_order_clause(options)
          return '$natural desc' unless options[:order]
          options[:order].split(',').map do |order_segment| 
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

        def find_from_ids(ids, options={})
          ids = ids.flatten.compact.uniq

          case ids.size
            when 0
              raise(DocumentNotFound, "Couldn't find without an ID")
            when 1
              find_one(ids[0], options)
            else
              find_some(ids, options)
          end
        end
        
        def find_with_args(args, options)
          attributes,  = {}
          find_options = args.extract_options!.deep_merge(:conditions => attributes)
          
          options[:attribute_names].each_with_index do |attr, index|
            attributes[attr] = args[index]
          end

          result = find(options[:finder], find_options)
          
          if result.nil?
            if options[:bang]
              raise DocumentNotFound, "Couldn't find Document with #{attributes.inspect} in collection named #{collection.name}"
            end
            
            if options[:instantiator]
              self.send(options[:instantiator], attributes)
            end
          else
            result
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

      def update_attributes(attrs={})
        self.attributes = attrs
        save
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

      # collection.save returns mongoid
      def save_to_collection
        clear_custom_id_flag
        collection.save(attributes)
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
