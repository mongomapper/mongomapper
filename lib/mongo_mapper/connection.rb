# encoding: UTF-8
require 'uri'

module MongoMapper
  module Connection
    @@connection    = nil
    @@database      = nil
    @@database_name = nil
    @@config        = nil

    # @api public
    def connection
      @@connection ||= Mongo::Connection.new
    end

    # @api public
    def connection=(new_connection)
      @@connection = new_connection
    end

    # @api public
    def logger
      connection.logger
    end

    # @api public
    def database=(name)
      @@database = nil
      @@database_name = name
    end

    # @api public
    def database
      return nil if @@database_name.blank?

      @@database ||= MongoMapper.connection.db(@@database_name)
    end

    def config=(hash)
      @@config = hash
    end

    def config
      raise 'Set config before connecting. MongoMapper.config = {...}' unless defined?(@@config)
      @@config
    end

    # @api private
    def config_for_environment(environment)
      env = config[environment.to_s] || {}
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

    def connect(environment, options={})
      raise 'Set config before connecting. MongoMapper.config = {...}' if config.blank?
      env = config_for_environment(environment)

      if env['options'].is_a? Hash
        options = env['options'].symbolize_keys.merge(options)
      end

      MongoMapper.connection = if env['hosts']
        if env['hosts'].first.is_a?(String)
          Mongo::ReplSetConnection.new( env['hosts'], options )
        else
          Mongo::ReplSetConnection.new( *env['hosts'].push(options) )
        end
      else
        Mongo::Connection.new(env['host'], env['port'], options)
      end

      MongoMapper.database = env['database']
      MongoMapper.database.authenticate(env['username'], env['password']) if env['username'] && env['password']
    end

    def setup(config, environment, options={})
      handle_passenger_forking
      self.config = config
      connect(environment, options)
    end

    def handle_passenger_forking
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          connection.connect if forked
        end
      end
    end
  end
end