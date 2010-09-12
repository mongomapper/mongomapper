require "mongo_mapper"
require "rails"
require "active_model/railtie"

module MongoMapper
  # = MongoMapper Railtie
  class Railtie < Rails::Railtie

    config.mongo_mapper = ActiveSupport::OrderedOptions.new

    config.paths.config.mongo 'config/mongo.yml'

    initializer "mongo_mapper.set_configs" do |app|
      ActiveSupport.on_load(:mongo_mapper) do
        app.config.mongo_mapper.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    # This sets the database configuration and establishes the connection.
    initializer "mongo_mapper.initialize_database" do
      config_file = config.paths.config.mongo
      if config_file.file?
        settings = YAML.load(ERB.new(config_file.read).result)[Rails.env]
        MongoMapper.setup(settings)
      end
    end

    # Clear the identity map after each request
    initializer "mongo_mapper.clear_identity_map", :before => :set_clear_dependencies_hook do |app|
      ActiveSupport.on_load(:mongo_mapper) do
        ActionDispatch::Callbacks.after do
          MongoMapper::Plugins::IdentityMap.clear
        end
      end
    end

    # See http://groups.google.com/group/mongomapper/browse_thread/thread/68f62e8eda43b43a/4841dba76938290c
    #
    # to_prepare is called before each request in development mode and the first request in production.
    config.to_prepare do
      unless config.cache_classes
        # Rails reloading was making descendants fill up and leak memory, these make sure they get cleared
        MongoMapper::Document.descendants.each {|m| m.descendants.clear if m.respond_to?(:descendants) }
        MongoMapper::Document.descendants.clear
        MongoMapper::EmbeddedDocument.descendants.each {|m| m.descendants.clear if m.respond_to?(:descendants) }
        MongoMapper::EmbeddedDocument.descendants.clear
        MongoMapper::Plugins::IdentityMap.models.clear
      end
    end
  end
end
