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
      expect(Mongo::Client).to receive(:new).with('mongodb://127.0.0.1:27017/test', {})
      MongoMapper.connect('development')
    end

    it "should work without authentication using hosts" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017']}
      }
      expect(Mongo::Client).to receive(:new).with(['127.0.0.1:27017'], {})
      MongoMapper.connect('development')
    end

    it "should work without authentication using host" do
      MongoMapper.config = {
        'development' => {'host' => ['127.0.0.1:27017']}
      }
      expect(Mongo::Client).to receive(:new).with(['127.0.0.1:27017'], {})
      MongoMapper.connect('development')
    end

    it "should convert read preferences to symbols" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017'], 'database' => 'test', 'read' => 'primary'}
      }
      logger = double('logger')
      expect(Mongo::Client).to receive(:new).with(['127.0.0.1:27017'], :logger => logger, :read => :primary, :database => 'test')
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options from config" do
      MongoMapper.config = {
        'development' => {'hosts' => ['192.168.1.1:2222'], 'database' => 'test', 'safe' => true}
      }
      logger = double('logger')
      expect(Mongo::Client).to receive(:new).with(['192.168.1.1:2222'], :logger => logger, :safe => true, :database => 'test')
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      logger = double('logger')
      expect(Mongo::Client).to receive(:new).with('mongodb://127.0.0.1:27017/test', :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with authentication" do
      MongoMapper.config = {
        'development' => {'hosts' => ['127.0.0.1:27017'], 'database' => 'test', 'user' => 'john', 'password' => 'secret'}
      }
      expect(Mongo::Client).to receive(:new).with(['127.0.0.1:27017'], :database => 'test', :user => 'john', :password => 'secret')
      MongoMapper.connect('development')
    end

    it "should work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      expect(Mongo::Client).to receive(:new).with('mongodb://john:secret@127.0.0.1:27017/test', {})
      MongoMapper.connect('development')
    end

    it "should raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      expect { MongoMapper.connect('development') }.to raise_error(Mongo::Error::InvalidURI)
    end

  end

  context "setup" do
    it "should work as shortcut for setting config, environment and options" do
      config, logger = double('config'), double('logger')
      expect(MongoMapper).to receive(:config=).with(config)
      expect(MongoMapper).to receive(:connect).with('development', :logger => logger)
      expect(MongoMapper).to receive(:handle_passenger_forking).once
      MongoMapper.setup(config, 'development', :logger => logger)
    end
  end
end
