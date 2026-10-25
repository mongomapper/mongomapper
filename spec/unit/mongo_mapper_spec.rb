require 'spec_helper'

class Address; end

describe "MongoMapper" do
  it "should be able to write and read connection", :without_connection do
    conn = Mongo::Client.new(['127.0.0.1:27001'])
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end

  it "should default connection to new mongo ruby driver", :without_connection do
    MongoMapper.connection = nil
    MongoMapper.connection.should be_instance_of(Mongo::Client)
  end

  it "should be able to read default database" do
    MongoMapper.database.should be_instance_of(Mongo::Database)
    MongoMapper.database.name.should == 'test'
  end

  it "should be able to write default database", :without_connection  do
    MongoMapper.database = 'test-2'
    MongoMapper.database.should be_instance_of(Mongo::Database)
    MongoMapper.database.name.should == 'test-2'
  end

  it "should have document not found error" do
    lambda {
      MongoMapper::DocumentNotFound
    }.should_not raise_error
  end

  it "should be able to read/write config" do
    config = {
      'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'},
      'production'  => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test-prod'}
    }
    MongoMapper.config = config
    MongoMapper.config.should == config
  end

  context "connecting to environment from config", :without_connection do

    it "should work without authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      Mongo::Client.should_receive(:new).with('mongodb://127.0.0.1:27017/test', { :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development')
    end

    it "should work without authentication using hosts" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017']}
      }
      Mongo::Client.should_receive(:new).with(['127.0.0.1:27017'], { :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development')
    end

    it "should work without authentication using host" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1:27017'}
      }
      Mongo::Client.should_receive(:new).with(['127.0.0.1:27017'], { :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development')
    end

    it "should convert read preferences to symbols" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017'], 'database' => 'test', 'read' => 'primary'}
      }
      logger = double('logger')
      Mongo::Client.should_receive(:new).with(['127.0.0.1:27017'], { :logger => logger, :read => :primary, :database => 'test', :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options from config" do
      MongoMapper.config = {
        'development' => {'hosts' => ['192.168.1.1:2222'], 'database' => 'test', 'safe' => true}
      }
      logger = double('logger')
      Mongo::Client.should_receive(:new).with(['192.168.1.1:2222'], { :logger => logger, :safe => true, :database => 'test', :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test', 'options'=> {:foo => 1}}
      }
      logger = double('logger')
      Mongo::Client.should_receive(:new).with('mongodb://127.0.0.1:27017/test', { :logger => logger, :foo => 1, :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with authentication" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017'], 'database' => 'test', 'user' => 'john', 'password' => 'secret'}
      }
      Mongo::Client.should_receive(:new).with(['127.0.0.1:27017'], { :database => 'test', :user => 'john', :password => 'secret', :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}] })
      MongoMapper.connect('development')
    end

    it "should work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      Mongo::Client.should_receive(:new).with('mongodb://john:secret@127.0.0.1:27017/test', { :wrapping_libraries=>[{:name=>"MongoMapper", :version=>::MongoMapper::Version}]})
      MongoMapper.connect('development')
    end

    it "should raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      lambda { MongoMapper.connect('development') }.should raise_error(Mongo::Error::InvalidURI)
    end

    it 'should forbid use of port' do
      MongoMapper.config = {
        'development' => {'host' => '192.168.1.1', 'port' => '27017', 'database' => 'test', 'safe' => true}
      }
      lambda { MongoMapper.connect('development') }.should raise_error(RuntimeError)
    end

  end

  context "setup" do
    it "should work as shortcut for setting config, environment and options" do
      config, logger = double('config'), double('logger')
      MongoMapper.should_receive(:config=).with(config)
      MongoMapper.should_receive(:connect).with('development',  { :logger => logger })
      MongoMapper.should_receive(:handle_passenger_forking).once
      MongoMapper.setup(config, 'development', :logger => logger)
    end

    it "should use the right reconnect method" do
      Mongo::Client.instance_methods.should_not include(:connect) # v1
      Mongo::Client.instance_methods.should include(:reconnect) # v1
    end
  end

  context "setup_with_config_file" do
    it "should work with config/simple.yml" do
      logger = double('logger')
      path = File.expand_path('../../config/simple.yml', __FILE__)
      MongoMapper.should_receive(:config=).with({
        "production" => { "host" => "127.0.0.1:21017", "database" => "production" },
        "development" => { "host" => "127.0.0.1:21017", "database" => "development" },
        "test" => { "host" => "127.0.0.1:21017", "database" => "test" },
      })
      MongoMapper.should_receive(:connect).with('development',  { :logger => logger })
      MongoMapper.should_receive(:handle_passenger_forking).once
      MongoMapper.setup_with_config_file(path, 'development', :logger => logger)
    end

    it "should work with config/alias.yml" do
      logger = double('logger')
      path = File.expand_path('../../config/alias.yml', __FILE__)
      MongoMapper.should_receive(:config=).with({
        "default" => { "host" => "127.0.0.1:21017" },
        "production" => { "host" => "127.0.0.1:21017", "database" => "production" },
        "development" => { "host" => "127.0.0.1:21017", "database" => "development" },
        "test" => { "host" => "127.0.0.1:21017", "database" => "test" },
      })
      MongoMapper.should_receive(:connect).with('development',  { :logger => logger })
      MongoMapper.should_receive(:handle_passenger_forking).once
      MongoMapper.setup_with_config_file(path, 'development', :logger => logger)
    end

    it "should work with config/erb.yml" do
      begin
        old_mongodb_uri, ENV["MONGODB_URI"] = ENV["MONGODB_URI"], "mongodb://127.0.0.1:21017/production"

        logger = double('logger')
        path = File.expand_path('../../config/erb.yml', __FILE__)
        MongoMapper.should_receive(:config=).with({
          "production" => { "uri" => "mongodb://127.0.0.1:21017/production" },
          "development" => { "host" => "127.0.0.1:21017", "database" => "development" },
          "test" => { "host" => "127.0.0.1:21017", "database" => "test" },
        })
        MongoMapper.should_receive(:connect).with('development',  { :logger => logger })
        MongoMapper.should_receive(:handle_passenger_forking).once
        MongoMapper.setup_with_config_file(path, 'development', :logger => logger)
      ensure
        ENV["MONGODB_URI"] = old_mongodb_uri
      end
    end
  end

  context "options" do
    it "should sets/returns filtered_attributes correctly" do
      MongoMapper.filter_attributes.should == []
      filtered_attributes = [:password, :credit_number]
      MongoMapper.filter_attributes = filtered_attributes
      MongoMapper.filter_attributes.should == filtered_attributes
    end
  end
end
