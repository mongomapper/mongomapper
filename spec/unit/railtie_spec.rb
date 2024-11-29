require 'spec_helper'
require 'mongo_mapper/railtie'

describe MongoMapper::Railtie do
  def with_rails(mongo_yml, &block)
    old_env, Rails.env = Rails.env, "test"
    old_time_zone_default = Time.zone_default

    Dir.mktmpdir do |rails_root|
      Dir.mkdir("#{rails_root}/config")
      File.write("#{rails_root}/config/mongo.yml", mongo_yml)

      fake_app = Module.new {
        def self.name
          'FakeApp'
        end

        const_set(:Application, Class.new(::Rails::Application) {
          config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}" if config.respond_to?(:load_defaults)
          config.eager_load = false
          config.root = rails_root
        })
      }
      fake_app::Application.initialize!

      block.call
    end
  ensure
    Rails.application = nil
    Rails.app_class = nil
    Rails.env = old_env
    Time.zone_default = old_time_zone_default
  end

  def with_temporary_configuration(&block)
    old_config = MongoMapper.config
    old_conn = MongoMapper.connection
    block.call
  ensure
    MongoMapper.config = old_config
    MongoMapper.connection = old_conn
  end

  describe "mongo_mapper.initialize_database" do
    around do |ex|
      with_temporary_configuration do
        mongo_yml = <<~YAML
          test:
            host: 127.0.0.1:21017
            database: fake_app_test
        YAML

        with_rails(mongo_yml) do
          ex.run
        end
      end
    end

    it "should load config from config/mongo.yml" do
      MongoMapper.config.should == {
        "test" => {"host" => "127.0.0.1:21017", "database" => "fake_app_test"},
      }
      MongoMapper.connection.cluster.addresses.map(&:to_s).should == ["127.0.0.1:21017"]
      MongoMapper.connection.database.name.should == "fake_app_test"
    end
  end
end
