# encoding: UTF-8
module MongoMapper
  module Document
    extend Support::DescendantAppends

    def self.included(model)
      model.class_eval do
        include InstanceMethods
        extend  ClassMethods
        extend  Plugins

        plugin Plugins::Associations
        plugin Plugins::Clone
        plugin Plugins::Descendants
        plugin Plugins::DynamicQuerying
        plugin Plugins::Equality
        plugin Plugins::Inspect
        plugin Plugins::Indexes
        plugin Plugins::Keys
        plugin Plugins::Dirty # for now dirty needs to be after keys
        plugin Plugins::Logger
        plugin Plugins::Modifiers
        plugin Plugins::Pagination
        plugin Plugins::Persistence
        plugin Plugins::Protected
        plugin Plugins::Querying
        plugin Plugins::Rails
        plugin Plugins::Sci
        plugin Plugins::Serialization
        plugin Plugins::Timestamps
        plugin Plugins::Userstamps
        plugin Plugins::Validations
        plugin Plugins::Callbacks # for now callbacks needs to be after validations

        extend Plugins::Validations::DocumentMacros
      end

      super
    end

    module ClassMethods
      def embeddable?
        false
      end
    end

    module InstanceMethods
      def save(options={})
        options.assert_valid_keys(:validate, :safe)
        options.reverse_merge!(:validate => true)
        !options[:validate] || valid? ? create_or_update(options) : false
      end

      def save!(options={})
        options.assert_valid_keys(:safe)
        save(options) || raise(DocumentNotValid.new(self))
      end

      def destroy
        delete
      end

      def delete
        @_destroyed = true
        self.class.delete(id) unless new?
      end

      def new?
        @new
      end

      def destroyed?
        @_destroyed == true
      end

      def reload
        if doc = self.class.query(:_id => id).first
          self.class.associations.each { |name, assoc| send(name).reset if respond_to?(name) }
          self.attributes = doc
          self
        else
          raise DocumentNotFound, "Document match #{_id.inspect} does not exist in #{collection.name} collection"
        end
      end

      # Used by embedded docs to find root easily without if/respond_to? stuff.
      # Documents are always root documents.
      def _root_document
        self
      end

    private
      def create_or_update(options={})
        result = new? ? create(options) : update(options)
        result != false
      end

      def create(options={})
        save_to_collection(options)
      end

      def update(options={})
        save_to_collection(options)
      end

      def save_to_collection(options={})
        safe = options[:safe] || false
        @new = false
        collection.save(to_mongo, :safe => safe)
      end
    end
  end # Document
end # MongoMapper
