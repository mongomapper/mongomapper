# encoding: UTF-8
module MongoMapper
  module EmbeddedDocument
    extend ActiveSupport::Concern
    extend Plugins

    include Plugins::ActiveModel
    include Plugins::EmbeddedDocument
    include Plugins::Associations
    include Plugins::Caching
    include Plugins::Clone
    include Plugins::Equality
    include Plugins::Inspect
    include Plugins::Keys
    include Plugins::Logger
    include Plugins::Persistence
    include Plugins::Accessible
    include Plugins::Protected
    include Plugins::Rails
    include Plugins::Sci
    include Plugins::Serialization
    include Plugins::Timestamps
    include Plugins::Validations
    include Plugins::EmbeddedCallbacks
    include Plugins::Touch

    included do
      extend Plugins
      extend Translation
    end
  end
end
