module MongoMapper  
  module Document
    def self.included(model)
      model.class_eval do
        include MongoMapper::EmbeddedDocument
        include InstanceMethods
        include SaveWithValidation
        include RailsCompatibility
        extend ClassMethods
        
        key :_id, String
        key :created_at, Time
        key :updated_at, Time
        
        define_callbacks  :before_create,  :after_create, 
                          :before_update,  :after_update,
                          :before_save,    :after_save,
                          :before_destroy, :after_destroy
      end
    end
    
    module ClassMethods
      def find(*args)
        options = args.extract_options!
        
        case args.first
          when :first then find_first(options)
          when :last  then find_last(options)
          when :all   then find_every(options)
          else             find_from_ids(args)
        end
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
        if doc = collection.find_first({:_id => id})
          new(doc)
        end
      end
      
      # TODO: remove the rescuing when ruby driver works correctly
      def count(conditions={})
        collection.count(conditions)
      end
      
      def create(*docs)
        instances = []
        docs.flatten.each { |attrs| instances << new(attrs).save }
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
        collection.remove(:_id => {'$in' => ids.flatten})
      end
      
      def delete_all(conditions={})
        collection.remove(conditions)
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
      
    private
      def find_every(options)
        criteria, options = FinderOptions.new(options).to_a
        collection.find(criteria, options).to_a.map { |doc| new(doc) }
      end

      def find_first(options)
        find_every(options.merge(:limit => 1, :order => 'created_at')).first
      end

      def find_last(options)
        find_every(options.merge(:limit => 1, :order => 'created_at desc')).first
      end

      def find_some(ids)
        documents = find_every(:conditions => {'_id' => ids})
        if ids.size == documents.size
          documents
        else
          raise DocumentNotFound, "Couldn't find all of the ids (#{ids.to_sentence}). Found #{documents.size}, but was expecting #{ids.size}"
        end
      end

      def find_from_ids(*ids)
        ids = ids.flatten.compact.uniq

        case ids.size
          when 0
            raise(DocumentNotFound, "Couldn't find without an ID")
          when 1
            find_by_id(ids[0]) || raise(DocumentNotFound, "Document with id of #{ids[0]} does not exist in collection named #{collection.name}")
          else
            find_some(ids)
        end
      end
      
      def update_single(id, attrs)
        if id.blank? || attrs.blank? || !attrs.is_a?(Hash)
          raise ArgumentError, "Updating a single document requires an id and a hash of attributes"
        end
        
        find(id).update_attributes(attrs)
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
        read_attribute('_id').blank? || self.class.find_by_id(id).blank?
      end
        
      def save
        run_callbacks(:before_save)
        new? ? create : update
        run_callbacks(:after_save)
        self
      end
    
      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end
    
      def destroy
        run_callbacks(:before_destroy)
        collection.remove(:_id => id) unless new?
        run_callbacks(:after_destroy)
        freeze
      end
    
      def ==(other)
        other.is_a?(self.class) && id == other.id
      end
    
    private
      def create
        write_attribute('_id', generate_id) if read_attribute('_id').blank?
        update_timestamps
        run_callbacks(:before_create)
        collection.insert(attributes_with_associations)
        run_callbacks(:after_create)
      end
    
      def update
        update_timestamps
        run_callbacks(:before_update)
        collection.modify({:_id => id}, attributes_with_associations)
        run_callbacks(:after_update)
      end
    
      def update_timestamps
        write_attribute('created_at', Time.now.utc) if new?
        write_attribute('updated_at', Time.now.utc)
      end
    
      def generate_id
        XGen::Mongo::Driver::ObjectID.new
      end
    end
  end # Document
end # MongoMapper
