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
      @@database ||= MongoMapper.connection.db(@@database_name)
    end

    def config=(hash)
      @@config = hash
    end

    def config
      raise 'Set config before connecting. MongoMapper.config = {...}' unless defined?(@@config)
      @@config
    end

    def connect(environment, options={})
      raise 'Set config before connecting. MongoMapper.config = {...}' if config.blank?
      env = config[environment.to_s] || {}

      if env['options'].is_a?(Hash)
        options = env['options'].symbolize_keys.merge(options)
      end

      if env.key?('ssl')
        options[:ssl] = env['ssl']
      end
      
      conn = Mongo::MongoClient.from_uri(uri(env), options)
      conn.apply_saved_authentication if conn.present?
      MongoMapper.connection = conn
    end

    # @api public
    def uri(env)
      return env['uri'] unless env['uri'].blank?
      'mongodb://'.tap do |uri|
        uri << "#{env['username']}:#{env['password']}@" if auth?(env)
        uri << "#{host(env)}"
        uri << "/#{env['database']}" if env['database']
      end
    end


    # @api public
    def auth?(env)
      env['username'] || env['password']
    end
    # @api public
    def host(env)
      return "#{env['host'] || 'localhost'}:#{env['port'] || 27017}" unless env['hosts']
      return env['hosts'] if env['hosts'].is_a?(String)
      return env['hosts'].join(',') if env['hosts'].first.is_a?(String)
      env['hosts'].collect{ |k| "#{k.first}:#{k.last}"}.join(',')
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
