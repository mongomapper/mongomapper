# encoding: UTF-8
module MongoMapper
  module Document
    extend Support::DescendantAppends

    def self.included(model)
      model.class_eval do
        extend  Plugins
        
        # TODO: Extract to plugin
        include ActiveModel::Serializers::Xml
        include ActiveModel::Conversion
        include ActiveModel::Naming
        include ActiveModel::Serialization
        include ActiveModel::Serializers::JSON
        extend ActiveModel::Translation

        plugin Plugins::Document
        plugin Plugins::Querying # for now needs to be before associations (save_to_collection)
        plugin Plugins::Associations
        plugin Plugins::Caching
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
        plugin Plugins::Accessible
        plugin Plugins::Protected
        plugin Plugins::Rails
        plugin Plugins::Safe # needs to be after querying (save_to_collection)
        plugin Plugins::Sci
        plugin Plugins::Scopes
        plugin Plugins::Serialization
        plugin Plugins::Timestamps
        plugin Plugins::Userstamps
        plugin Plugins::Validations
        plugin Plugins::Callbacks # for now callbacks needs to be after validations
      end
      super
    end
  end # Document
end # MongoMapper
