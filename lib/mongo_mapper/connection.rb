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
      @@connection ||= Mongo::MongoClient.new
    end

    def connection?
      !!@@connection
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
      full_config = config_for_environment(environment)

      env = {
        'hosts'    => full_config.delete('hosts'),
        'host'     => full_config.delete('host'),
        'port'     => full_config.delete('port'),
        'database' => full_config.delete('database'),
        'username' => full_config.delete('username'),
        'password' => full_config.delete('password')
      }

      options = full_config.merge(options).symbolize_keys

      if env['options'].is_a?(Hash)
        options = env['options'].symbolize_keys.merge(options)
      end
      options[:read] = options[:read].to_sym if options[:read].is_a? String

      if env.key?('ssl')
        options[:ssl] = env['ssl']
      end

      MongoMapper.connection = if env.key?('hosts')
        klass = (env.key?("mongos") || env.key?("sharded")) ? Mongo::MongoShardedClient : Mongo::MongoReplicaSetClient
        if env['hosts'].first.is_a?(String)
          klass.new( env['hosts'], options )
        else
          klass.new( *env['hosts'].push(options) )
        end
      else
        Mongo::MongoClient.new(env['host'], env['port'], options)
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
      # :nocov:
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          connection.connect if forked
        end
      end
      # :nocov:
    end
  end
end
