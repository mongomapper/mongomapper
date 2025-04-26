# encoding: UTF-8
require 'uri'

module MongoMapper
  module Connection
    @@connection    = nil
    @@config        = nil
    @@database      = nil

    # @api public
    def connection
      @@connection ||= Mongo::Client.new ['127.0.0.1:27017']
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
      @@database = connection.use(name).database
    end

    # @api public
    def database
      @@database ||= connection.database
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
      config[environment.to_s]
    end

    def connect(environment, options={})
      raise 'Set config before connecting. MongoMapper.config = {...}' if config.blank?
      env = config_for_environment(environment).dup
      addresses_or_uri = env.delete('hosts') ||
                         env.delete('uri') ||
                         [env.delete('host')].compact

      if env['options'].is_a?(Hash)
        options = env.delete('options').symbolize_keys.merge(options)
      end
      #database etc are all options to Mongo::Client.new now
      options = env.symbolize_keys.merge(options)

      if options[:port]
        raise "port should be specified as part of the host or uri"
      end

      options[:read] = options[:read].to_sym if options[:read].is_a? String
      MongoMapper.connection = Mongo::Client.new(addresses_or_uri, options)
    end

    def setup(config, environment, options={})
      handle_passenger_forking
      self.config = config
      connect(environment, options)
    end

    def setup_with_config_file(path, environment, options={})
      source = ERB.new(File.read(path)).result
      config = YAML.load(source, aliases: true)
      MongoMapper.setup(config, environment, options)
    end

    def handle_passenger_forking
      # :nocov:
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          connection.reconnect if forked
        end
      end
      # :nocov:
    end
  end
end
