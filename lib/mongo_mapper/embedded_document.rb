# encoding: UTF-8
module MongoMapper
  module EmbeddedDocument
    extend Support::DescendantAppends
    extend ActiveSupport::Concern

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
    include Plugins::Validations
    include Plugins::EmbeddedCallbacks

    included do
      extend Plugins
    end
  end
end
