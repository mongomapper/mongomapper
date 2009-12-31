require 'set'

module MongoMapper
  module Document
    def self.included(model)
      model.class_eval do
        include EmbeddedDocument
        include InstanceMethods
        include Observing
        include Callbacks
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
      def key(*args)
        key = super
        create_indexes_for(key)
        key
      end

      def ensure_index(name_or_array, options={})
        keys_to_index = if name_or_array.is_a?(Array)
          name_or_array.map { |pair| [pair[0], pair[1]] }
        else
          name_or_array
        end

        MongoMapper.ensure_index(self, keys_to_index, options)
      end

      # @overload find(:first, options)
      #   @see Document.first
      #
      # @overload find(:last, options)
      #   @see Document.last
      #
      # @overload find(:all, options)
      #   @see Document.all
      #
      # @overload find(ids, options)
      #
      # @raise DocumentNotFound raised when no ID or arguments are provided
      def find!(*args)
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
                find_one!(options.merge({:_id => args[0]}))
              else
                find_some(args, options)
            end
        end
      end
      
      def find(*args)
        find!(*args)
      rescue DocumentNotFound
        nil
      end

      def paginate(options)
        per_page      = options.delete(:per_page) || self.per_page
        page          = options.delete(:page)
        total_entries = count(options)
        pagination    = Pagination::PaginationProxy.new(total_entries, page, per_page)

        options.merge!(:limit => pagination.limit, :skip => pagination.skip)
        pagination.subject = find_every(options)
        pagination
      end

      # @param [Hash] options any conditions understood by 
      #   FinderOptions.to_mongo_criteria
      #
      # @return the first document in the ordered collection as described by 
      #   +options+
      #
      # @see FinderOptions
      def first(options={})
        find_one(options)
      end

      # @param [Hash] options any conditions understood by 
      #   FinderOptions.to_mongo_criteria
      # @option [String] :order this *mandatory* option describes how to 
      #   identify the ordering of the documents in your collection. Note that 
      #   the *last* document in this collection will be selected.
      #
      # @return the last document in the ordered collection as described by 
      #   +options+
      #
      # @raise Exception when no <tt>:order</tt> option has been defined
      def last(options={})
        raise ':order option must be provided when using last' if options[:order].blank?
        find_one(options.merge(:order => invert_order_clause(options[:order])))
      end

      # @param [Hash] options any conditions understood by 
      #   FinderOptions.to_mongo_criteria
      #
      # @return [Array] all documents in your collection that match the 
      #   provided conditions
      #
      # @see FinderOptions
      def all(options={})
        find_every(options)
      end

      def find_by_id(id)
        find_one(:_id => id)
      end

      def count(options={})
        collection.find(to_criteria(options)).count
      end

      def exists?(options={})
        !count(options).zero?
      end

      # @overload create(doc_attributes)
      #   Create a single new document
      #   @param [Hash] doc_attributes key/value pairs to create a new 
      #     document
      #
      # @overload create(docs_attributes)
      #   Create many new documents
      #   @param [Array<Hash>] provide many Hashes of key/value pairs to create 
      #     multiple documents
      #
      # @example Creating a single document
      #   MyModel.create({ :foo => "bar" })
      #
      # @example Creating multiple documents
      #   MyModel.create([{ :foo => "bar" }, { :foo => "baz" })
      #
      # @return [Boolean] when a document is successfully created, +true+ will 
      #   be returned. If a document fails to create, +false+ will be returned.
      def create(*docs)
        initialize_each(*docs) { |doc| doc.save }
      end

      # @see Document.create
      #
      # @raise [DocumentNotValid] raised if a document fails to create
      def create!(*docs)
        initialize_each(*docs) { |doc| doc.save! }
      end

      # @overload update(id, attributes)
      #   Update a single document
      #   @param id the ID of the document you wish to update
      #   @param [Hash] attributes the key to update on the document with a new 
      #     value
      #
      # @overload update(ids_and_attributes)
      #   Update multiple documents
      #   @param [Hash] ids_and_attributes each key is the ID of some document 
      #     you wish to update. The value each key points toward are those 
      #     applied to the target document
      #
      # @example Updating single document
      #   Person.update(1, {:foo => 'bar'})
      #
      # @example Updating multiple documents at once:
      #   Person.update({'1' => {:foo => 'bar'}, '2' => {:baz => 'wick'}})
      def update(*args)
        if args.length == 1
          update_multiple(args[0])
        else
          id, attributes = args
          update_single(id, attributes)
        end
      end

      # Removes ("deletes") one or many documents from the collection. Note 
      # that this will bypass any +destroy+ hooks defined by your class.
      #
      # @param [Array] ids the ID or IDs of the records you wish to delete
      def delete(*ids)
        collection.remove(to_criteria(:_id => ids.flatten))
      end

      def delete_all(options={})
        collection.remove(to_criteria(options))
      end

      # Iterates over each document found by the provided IDs and calls their 
      # +destroy+ method. This has the advantage of processing your document's 
      # +destroy+ call-backs.
      #
      # @overload destroy(id)
      #   Destroy a single document by ID
      #   @param id the ID of the document to destroy
      #
      # @overload destroy(ids)
      #   Destroy many documents by their IDs
      #   @param [Array] the IDs of each document you wish to destroy
      #
      # @example Destroying a single document
      #   Person.destroy("34")
      #
      # @example Destroying multiple documents
      #   Person.destroy("34", "45", ..., "54")
      #
      #   # OR...
      #
      #   Person.destroy(["34", "45", ..., "54"])
      def destroy(*ids)
        find_some(ids.flatten).each(&:destroy)
      end

      def destroy_all(options={})
        all(options).each(&:destroy)
      end
      
      def increment(*args)
        criteria, keys = criteria_and_keys_from_args(args)
        modifiers      = {'$inc' => keys}
        collection.update(criteria, modifiers, :multi => true)
      end
      
      def decrement(*args)
        criteria, keys = criteria_and_keys_from_args(args)
        # to make sure that counts are always negative
        keys           = keys.inject({}) { |hash, h| hash[h[0]] = -h[1].abs; hash }
        modifiers      = {'$inc' => keys}
        collection.update(criteria, modifiers, :multi => true)
      end
      
      def criteria_and_keys_from_args(args)
        keys     = args.pop
        criteria = args[0].is_a?(Hash) ? args[0] : {:id => args}
        [to_criteria(criteria), keys]
      end
      private :criteria_and_keys_from_args

      # @overload connection()
      #   @return [Mongo::Connection] the connection used by your document class
      #
      # @overload connection(mongo_connection)
      #   @param [Mongo::Connection] mongo_connection a new connection for your 
      #     document class to use
      #   @return [Mongo::Connection] a new Mongo::Connection for yoru document 
      #     class
      def connection(mongo_connection=nil)
        if mongo_connection.nil?
          @connection ||= MongoMapper.connection
        else
          @connection = mongo_connection
        end
        @connection
      end

      # Changes the database name from the default to whatever you want
      #
      # @param [#to_s] name the new database name to use.
      def set_database_name(name)
        @database_name = name
      end
      
      # Returns the database name
      #
      # @return [String] the database name
      def database_name
        @database_name
      end

      # Returns the database the document should use. Defaults to
      #   MongoMapper.database if other database is not set.
      #
      # @return [Mongo::DB] the mongo database instance
      def database
        if database_name.nil?
          MongoMapper.database
        else
          connection.db(database_name)
        end
      end

      # Changes the collection name from the default to whatever you want
      #
      # @param [#to_s] name the new collection name to use.
      def set_collection_name(name)
        @collection_name = name
      end

      # Returns the collection name, if not set, defaults to class name tableized
      #
      # @return [String] the collection name, if not set, defaults to class 
      #   name tableized
      def collection_name
        @collection_name ||= self.to_s.tableize.gsub(/\//, '.')
      end

      # @return the Mongo Ruby driver +collection+ object
      def collection
        database.collection(collection_name)
      end
      
      # Defines a +created_at+ and +updated_at+ attribute (with a +Time+ 
      # value) on your document. These attributes are updated by an 
      # injected +update_timestamps+ +before_save+ hook.
      def timestamps!
        key :created_at, Time
        key :updated_at, Time
        class_eval { before_save :update_timestamps }
      end

      def single_collection_inherited?
        keys.has_key?('_type') && single_collection_inherited_superclass?
      end

      def single_collection_inherited_superclass?
        superclass.respond_to?(:keys) && superclass.keys.has_key?('_type')
      end

      private
        def create_indexes_for(key)
          ensure_index key.name if key.options[:index]
        end

        def initialize_each(*docs)
          instances = []
          docs = [{}] if docs.blank?
          docs.flatten.each do |attrs|
            doc = initialize_doc(attrs)
            yield(doc)
            instances << doc
          end
          instances.size == 1 ? instances[0] : instances
        end

        def find_every(options)
          criteria, options = to_finder_options(options)
          collection.find(criteria, options).to_a.map do |doc|
            initialize_doc(doc)
          end
        end

        def find_some(ids, options={})
          ids       = ids.flatten.compact.uniq
          documents = find_every(options.merge(:_id => ids))

          if ids.size == documents.size
            documents
          else
            raise DocumentNotFound, "Couldn't find all of the ids (#{ids.to_sentence}). Found #{documents.size}, but was expecting #{ids.size}"
          end
        end

        def find_one(options={})
          criteria, options = to_finder_options(options)
          if doc = collection.find_one(criteria, options)
            initialize_doc(doc)
          end
        end

        def find_one!(options={})
          find_one(options) || raise(DocumentNotFound, "Document match #{options.inspect} does not exist in #{collection.name} collection")
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

        def to_criteria(options={})
          FinderOptions.new(self, options).criteria
        end

        def to_finder_options(options={})
          FinderOptions.new(self, options).to_a
        end
    end

    module InstanceMethods
      def collection
        self.class.collection
      end

      def new?
        read_attribute('_id').blank? || using_custom_id?
      end

      def save(perform_validations=true)
        !perform_validations || valid? ? create_or_update : false
      end

      def save!
        save || raise(DocumentNotValid.new(self))
      end

      def destroy
        self.class.delete(_id) unless new?
      end
      
      def delete
        self.class.delete(_id) unless new?
      end

      def reload
        doc = self.class.find(_id)
        self.class.associations.each { |name, assoc| send(name).reset if respond_to?(name) }
        self.attributes = doc.attributes
        self
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
          write_attribute :_id, Mongo::ObjectID.new
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
        write_attribute('created_at', now) if new? && read_attribute('created_at').blank?
        write_attribute('updated_at', now)
      end

      def clear_custom_id_flag
        @using_custom_id = nil
      end
    end
  end # Document
end # MongoMapper
