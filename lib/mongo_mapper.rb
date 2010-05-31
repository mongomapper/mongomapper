# encoding: UTF-8
# Make sure you have the correct versions of the gems (see gemspec) in your load path.
require 'set'
require 'uri'
require 'plucky'
require 'validatable'
require 'active_support/all'

module MongoMapper
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

  autoload :Error,            'mongo_mapper/exceptions'
  autoload :KeyNotFound,      'mongo_mapper/exceptions'
  autoload :DocumentNotFound, 'mongo_mapper/exceptions'
  autoload :InvalidScheme,    'mongo_mapper/exceptions'
  autoload :DocumentNotValid, 'mongo_mapper/exceptions'

  autoload :Document,         'mongo_mapper/document'
  autoload :EmbeddedDocument, 'mongo_mapper/embedded_document'
  autoload :Plugins,          'mongo_mapper/plugins'
  autoload :Version,          'mongo_mapper/version'

  module Plugins
    autoload :Associations,     'mongo_mapper/plugins/associations'
    autoload :Callbacks,        'mongo_mapper/plugins/callbacks'
    autoload :Clone,            'mongo_mapper/plugins/clone'
    autoload :Descendants,      'mongo_mapper/plugins/descendants'
    autoload :Dirty,            'mongo_mapper/plugins/dirty'
    autoload :Document,         'mongo_mapper/plugins/document'
    autoload :DynamicQuerying,  'mongo_mapper/plugins/dynamic_querying'
    autoload :EmbeddedDocument, 'mongo_mapper/plugins/embedded_document'
    autoload :Equality,         'mongo_mapper/plugins/equality'
    autoload :IdentityMap,      'mongo_mapper/plugins/identity_map'
    autoload :Inspect,          'mongo_mapper/plugins/inspect'
    autoload :Indexes,          'mongo_mapper/plugins/indexes'
    autoload :Keys,             'mongo_mapper/plugins/keys'
    autoload :Logger,           'mongo_mapper/plugins/logger'
    autoload :Modifiers,        'mongo_mapper/plugins/modifiers'
    autoload :Pagination,       'mongo_mapper/plugins/pagination'
    autoload :Persistence,      'mongo_mapper/plugins/persistence'
    autoload :Protected,        'mongo_mapper/plugins/protected'
    autoload :Querying,         'mongo_mapper/plugins/querying'
    autoload :Rails,            'mongo_mapper/plugins/rails'
    autoload :Safe,             'mongo_mapper/plugins/safe'
    autoload :Sci,              'mongo_mapper/plugins/sci'
    autoload :Serialization,    'mongo_mapper/plugins/serialization'
    autoload :Timestamps,       'mongo_mapper/plugins/timestamps'
    autoload :Userstamps,       'mongo_mapper/plugins/userstamps'
    autoload :Validations,      'mongo_mapper/plugins/validations'

    module Associations
      autoload :Base,                         'mongo_mapper/plugins/associations/base'
      autoload :Collection,                   'mongo_mapper/plugins/associations/collection'
      autoload :EmbeddedCollection,           'mongo_mapper/plugins/associations/embedded_collection'
      autoload :ManyDocumentsProxy,           'mongo_mapper/plugins/associations/many_documents_proxy'
      autoload :BelongsToProxy,               'mongo_mapper/plugins/associations/belongs_to_proxy'
      autoload :BelongsToPolymorphicProxy,    'mongo_mapper/plugins/associations/belongs_to_polymorphic_proxy'
      autoload :ManyPolymorphicProxy,         'mongo_mapper/plugins/associations/many_polymorphic_proxy'
      autoload :ManyEmbeddedProxy,            'mongo_mapper/plugins/associations/many_embedded_proxy'
      autoload :ManyEmbeddedPolymorphicProxy, 'mongo_mapper/plugins/associations/many_embedded_polymorphic_proxy'
      autoload :ManyDocumentsAsProxy,         'mongo_mapper/plugins/associations/many_documents_as_proxy'
      autoload :OneProxy,                     'mongo_mapper/plugins/associations/one_proxy'
      autoload :OneEmbeddedProxy,             'mongo_mapper/plugins/associations/one_embedded_proxy'
      autoload :InArrayProxy,                 'mongo_mapper/plugins/associations/in_array_proxy'
    end

    module DynamicQuerying
      autoload :DynamicFinder, 'mongo_mapper/plugins/dynamic_querying/dynamic_finder'
    end

    module Keys
      autoload :Key, 'mongo_mapper/plugins/keys/key'
    end
    
    module Querying
      autoload :Decorator, 'mongo_mapper/plugins/querying/decorator'
    end
  end

  module Support
    autoload :DescendantAppends, 'mongo_mapper/support/descendant_appends'
  end
end

Dir[File.join(File.dirname(__FILE__), 'mongo_mapper', 'extensions', '*.rb')].each do |extension|
  require extension
end

# FIXME: autoload with proxy is failing, need to investigate
require 'mongo_mapper/plugins/associations/proxy'