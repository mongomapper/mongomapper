# encoding: UTF-8
module MongoMapper
  module EmbeddedDocument
    extend Support::DescendantAppends

    def self.included(model)
      model.class_eval do
        extend  Plugins

        plugin Plugins::EmbeddedDocument
        plugin Plugins::Associations
        plugin Plugins::Caching
        plugin Plugins::Clone
        plugin Plugins::Descendants
        plugin Plugins::Equality
        plugin Plugins::Inspect
        plugin Plugins::Keys
        plugin Plugins::Logger
        plugin Plugins::Persistence
        plugin Plugins::Accessible
        plugin Plugins::Protected
        plugin Plugins::Rails
        plugin Plugins::Sci
        plugin Plugins::Serialization
        plugin Plugins::Validations
        plugin Plugins::Callbacks
      end
      super
    end
  end
end
