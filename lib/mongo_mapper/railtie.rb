require "mongo_mapper"
require "rails"
require "active_model/railtie"
require "yaml"

# Need the action_dispatch railtie to have action_dispatch.rescu_responses initialized correctly
require "action_dispatch/railtie"

module MongoMapper
  # = MongoMapper Railtie
  class Railtie < Rails::Railtie

    config.mongo_mapper = ActiveSupport::OrderedOptions.new

    # Rescue responses similar to ActiveRecord.
    # For rails 3.0 and 3.1
    if Rails.version < "3.2"
      ActionDispatch::ShowExceptions.rescue_responses['MongoMapper::DocumentNotFound']  = :not_found
      ActionDispatch::ShowExceptions.rescue_responses['MongoMapper::InvalidKey']        = :unprocessable_entity
      ActionDispatch::ShowExceptions.rescue_responses['MongoMapper::InvalidScheme']     = :unprocessable_entity
      ActionDispatch::ShowExceptions.rescue_responses['MongoMapper::NotSupported']      = :unprocessable_entity
    else
      # For rails 3.2 and 4.0
      config.action_dispatch.rescue_responses.merge!(
          'MongoMapper::DocumentNotFound'  => :not_found,
          'MongoMapper::InvalidKey'        => :unprocessable_entity,
          'MongoMapper::InvalidScheme'     => :unprocessable_entity,
          'MongoMapper::NotSupported'      => :unprocessable_entity
        )
    end

    rake_tasks do
      load "mongo_mapper/railtie/database.rake"
    end

    initializer "mongo_mapper.set_configs" do |app|
      ActiveSupport.on_load(:mongo_mapper) do
        app.config.mongo_mapper.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    if Rails.version >= "6.0"
      initializer "mongo_mapper.filter_attributes=" do |app|
        ActiveSupport.on_load(:mongo_mapper) do
          MongoMapper.filter_attributes += app.config.filter_parameters
        end
      end
    end

    initializer "mongo_mapper.deprecator" do |app|
      app.deprecators[:mongo_mapper] = MongoMapper.deprecator if app.respond_to?(:deprecators)
    end

    # This sets the database configuration and establishes the connection.
    initializer "mongo_mapper.initialize_database" do |app|
      config_file = Rails.root.join('config/mongo.yml')
      if config_file.file?
        MongoMapper.setup_with_config_file(config_file, Rails.env, :logger => Rails.logger)
      end
    end
  end
end
