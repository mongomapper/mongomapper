require 'set'

module MongoMapper
  module Document
    def self.included(model)
      model.class_eval do
        include EmbeddedDocument
        include InstanceMethods
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

      extra_extensions.each { |extension| model.extend(extension) }
      extra_inclusions.each { |inclusion| model.send(:include, inclusion) }

      descendants << model
    end

    def self.descendants
      @descendants ||= Set.new
    end

    def self.append_extensions(*extensions)
      extra_extensions.concat extensions

      # Add the extension to existing descendants
      descendants.each do |model|
        extensions.each { |extension| model.extend(extension) }
      end
    end

    # @api private
    def self.extra_extensions
      @extra_extensions ||= []
    end

    def self.append_inclusions(*inclusions)
      extra_inclusions.concat inclusions

      # Add the inclusion to existing descendants
      descendants.each do |model|
        inclusions.each { |inclusion| model.send :include, inclusion }
      end
    end

    # @api private
    def self.extra_inclusions
      @extra_inclusions ||= []
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

      def first(options={})
        find_one(options)
      end

      def last(options={})
        raise ':order option must be provided when using last' if options[:order].blank?
        find_one(options.merge(:order => invert_order_clause(options[:order])))
      end

      def all(options={})
        find_every(options)
      end

      def find_by_id(id)
        find(id)
      end

      def count(options={})
        collection.find(to_criteria(options)).count
      end

      def exists?(options={})
        !count(options).zero?
      end

      def create(*docs)
        initialize_each(*docs) { |doc| doc.save }
      end

      def create!(*docs)
        initialize_each(*docs) { |doc| doc.save! }
      end

      def update(*args)
        if args.length == 1
          update_multiple(args[0])
        else
          id, attributes = args
          update_single(id, attributes)
        end
      end

      def delete(*ids)
        collection.remove(to_criteria(:_id => ids.flatten))
      end

      def delete_all(options={})
        collection.remove(to_criteria(options))
      end

      def destroy(*ids)
        find_some(ids.flatten).each(&:destroy)
      end

      def destroy_all(options={})
        all(options).each(&:destroy)
      end
      
      def increment(*args)
        modifier_update('$inc', args)
      end
      
      def decrement(*args)
        criteria, keys = criteria_and_keys_from_args(args)
        values, to_decrement = keys.values, {}
        keys.keys.each_with_index { |k, i| to_decrement[k] = -values[i].abs }
        collection.update(criteria, {'$inc' => to_decrement}, :multi => true)
      end
      
      def set(*args)
        modifier_update('$set', args)
      end
      
      def push(*args)
        modifier_update('$push', args)
      end
      
      def push_all(*args)
        modifier_update('$pushAll', args)
      end
      
      def push_uniq(*args)
        criteria, keys = criteria_and_keys_from_args(args)
        keys.each { |key, value | criteria[key] = {'$ne' => value} }
        collection.update(criteria, {'$push' => keys}, :multi => true)
      end
      
      def pull(*args)
        modifier_update('$pull', args)
      end
      
      def pull_all(*args)
        modifier_update('$pullAll', args)
      end
      
      def modifier_update(modifier, args)
        criteria, keys = criteria_and_keys_from_args(args)
        modifiers = {modifier => keys}
        collection.update(criteria, modifiers, :multi => true)
      end
      private :modifier_update
      
      def criteria_and_keys_from_args(args)
        keys     = args.pop
        criteria = args[0].is_a?(Hash) ? args[0] : {:id => args}
        [to_criteria(criteria), keys]
      end
      private :criteria_and_keys_from_args

      def connection(mongo_connection=nil)
        if mongo_connection.nil?
          @connection ||= MongoMapper.connection
        else
          @connection = mongo_connection
        end
        @connection
      end

      def set_database_name(name)
        @database_name = name
      end
      
      def database_name
        @database_name
      end

      def database
        if database_name.nil?
          MongoMapper.database
        else
          connection.db(database_name)
        end
      end

      def set_collection_name(name)
        @collection_name = name
      end

      def collection_name
        @collection_name ||= self.to_s.tableize.gsub(/\//, '.')
      end

      def collection
        database.collection(collection_name)
      end

      def timestamps!
        key :created_at, Time
        key :updated_at, Time
        class_eval { before_save :update_timestamps }
      end

      def userstamps!
        key :creator_id, ObjectId
        key :updater_id, ObjectId
        belongs_to :creator, :class_name => 'User'
        belongs_to :updater, :class_name => 'User'
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
      
      def database
        self.class.database
      end

      def new?
        read_attribute('_id').blank? || using_custom_id?
      end

      def save(options={})
        if options === false
          ActiveSupport::Deprecation.warn "save with true/false is deprecated. You should now use :validate => true/false."
          options = {:validate => false}
        end
        options.reverse_merge!(:validate => true)
        perform_validations = options.delete(:validate)
        !perform_validations || valid? ? create_or_update(options) : false
      end

      def save!
        save || raise(DocumentNotValid.new(self))
      end

      def destroy
        self.class.delete(id) unless new?
      end
      
      def delete
        self.class.delete(id) unless new?
      end

      def reload
        doc = self.class.find(_id)
        self.class.associations.each { |name, assoc| send(name).reset if respond_to?(name) }
        self.attributes = doc.attributes
        self
      end

    private
      def create_or_update(options={})
        result = new? ? create(options) : update(options)
        result != false
      end

      def create(options={})
        assign_id
        save_to_collection(options)
      end

      def assign_id
        if read_attribute(:_id).blank?
          write_attribute :_id, Mongo::ObjectID.new
        end
      end

      def update(options={})
        save_to_collection(options)
      end

      def save_to_collection(options={})
        clear_custom_id_flag
        safe = options.delete(:safe) || false
        collection.save(to_mongo, :safe => safe)
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
