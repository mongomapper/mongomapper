require 'spec_helper'

describe "Railtie" do
  require "rails"

  describe "mongo_mapper.initialize_database" do
    around do |ex|
      old_config = MongoMapper.config
      old_conn = MongoMapper.connection
      old_db = MongoMapper.database.name

      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p("#{dir}/config")
        File.write("#{dir}/config/mongo.yml", <<~YAML)
          development:
            database: example_mongodb_development
          test:
            database: example_mongodb_test
          production:
            database: example_mongodb
        YAML
        File.write("#{dir}/config/environment.rb", <<~RUBY)
          module FakeApp
            class Application < Rails::Application
              config.root = "#{dir}"
              config.eager_load = false
            end
          end
        RUBY

        require "mongo_mapper/railtie"
        require "#{dir}/config/environment"
        FakeApp::Application.initialize!

        ex.run
      end

      MongoMapper.config = old_config
      MongoMapper.connection = old_conn
      MongoMapper.database = old_db
    end

    it "should load config from config/mongo.yml" do
      MongoMapper.config.should == {
        "development" => {"database" => "example_mongodb_development"},
        "test" => {"database" => "example_mongodb_test"},
        "production" => {"database" => "example_mongodb"},
      }
    end
  end
end
