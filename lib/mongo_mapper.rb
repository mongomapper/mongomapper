# encoding: UTF-8
# Make sure you have the correct versions of the gems (see gemspec) in your load path.
require 'set'
require 'uri'
require 'plucky'
require 'validatable'
require 'active_support/all'

module MongoMapper
  # generic MM error
  class MongoMapperError < StandardError; end

  # raised when key expected to exist but not found
  class KeyNotFound < MongoMapperError; end

  # raised when document expected but not found
  class DocumentNotFound < MongoMapperError; end

  # raised when trying to connect using uri with incorrect scheme
  class InvalidScheme < MongoMapperError; end

  # raised when document not valid and using !
  class DocumentNotValid < MongoMapperError
    def initialize(document)
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end

  # @api public
  def self.connection
    @@connection ||= Mongo::Connection.new
  end

  # @api public
  def self.connection=(new_connection)
    @@connection = new_connection
  end

  # @api public
  def self.logger
    connection.logger
  end

  # @api public
  def self.database=(name)
    @@database = nil
    @@database_name = name
  end

  # @api public
  def self.database
    if @@database_name.blank?
      raise 'You forgot to set the default database name: MongoMapper.database = "foobar"'
    end

    @@database ||= MongoMapper.connection.db(@@database_name)
  end

  def self.config=(hash)
    @@config = hash
  end

  def self.config
    raise 'Set config before connecting. MongoMapper.config = {...}' unless defined?(@@config)
    @@config
  end

  # @api private
  def self.config_for_environment(environment)
    env = config[environment]
    return env if env['uri'].blank?

    uri = URI.parse(env['uri'])
    raise InvalidScheme.new('must be mongodb') unless uri.scheme == 'mongodb'
    {
      'host'     => uri.host,
      'port'     => uri.port,
      'database' => uri.path.gsub(/^\//, ''),
      'username' => uri.user,
      'password' => uri.password,
    }
  end

  def self.connect(environment, options={})
    raise 'Set config before connecting. MongoMapper.config = {...}' if config.blank?
    env = config_for_environment(environment)
    MongoMapper.connection = Mongo::Connection.new(env['host'], env['port'], options)
    MongoMapper.database = env['database']
    MongoMapper.database.authenticate(env['username'], env['password']) if env['username'] && env['password']
  end

  def self.setup(config, environment, options={})
    handle_passenger_forking
    self.config = config
    connect(environment, options)
  end

  def self.handle_passenger_forking
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        connection.connect_to_master if forked
      end
    end
  end

  autoload :Document,         'mongo_mapper/document'
  autoload :EmbeddedDocument, 'mongo_mapper/embedded_document'
  autoload :Query,            'mongo_mapper/query'
  autoload :Version,          'mongo_mapper/version'
  
  module Support
    autoload :DescendantAppends, 'mongo_mapper/support/descendant_appends'
  end
end

require 'mongo_mapper/extensions'
require 'mongo_mapper/plugins'
