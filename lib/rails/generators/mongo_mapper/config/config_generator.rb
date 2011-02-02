# encoding: utf-8

module MongoMapper
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc "creates the MongoMapper configuration at config/mongo.yml"

      argument :database_name, :type => :string, :optional => true

      def self.source_root
        @source_root ||= File.expand_path("../templates", __FILE__)
      end

      def app_name
        Rails::Application.subclasses.first.parent.to_s.underscore
      end

      def create_config_file
        template 'mongo.yml', File.join('config', "mongo.yml")
      end

    end
  end
end
