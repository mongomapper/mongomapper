# encoding: utf-8

module MongoMapper
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc 'creates the MongoMapper configuration at config/mongo.yml'

      argument :database_name, :type => :string, :optional => true

      def self.source_root
        @source_root ||= File.expand_path('../templates', __FILE__)
      end

      def create_config_file
        template 'mongo.yml', File.join('config', 'mongo.yml')
      end

      protected

        def app_name
          @app_name ||= defined_app_const_base? ? defined_app_name : File.basename(destination_root)
        end

        def defined_app_name
          defined_app_const_base.underscore
        end

        def defined_app_const_base
          Rails.respond_to?(:application) && defined?(Rails::Application) &&
            Rails.application.is_a?(Rails::Application) && Rails.application.class.name.sub(/::Application$/, '')
        end

        alias :defined_app_const_base? :defined_app_const_base

    end
  end
end
