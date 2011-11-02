require 'spec_helper'

class Address; end

describe MongoMapper do
  it "should be able to write and read connection" do
    conn = Mongo::Connection.new
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end

  it "should default connection to new mongo ruby driver" do
    MongoMapper.connection = nil
    MongoMapper.connection.should be_instance_of(Mongo::Connection)
  end

  it "should be able to write and read default database" do
    MongoMapper.database = 'test'
    MongoMapper.database.should be_instance_of(Mongo::DB)
    MongoMapper.database.name.should == 'test'
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

  context "connecting to environment from config" do
    it "should work without authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      Mongo::Connection.should_receive(:new).with('127.0.0.1', 27017, {})
      MongoMapper.should_receive(:database=).with('test')
      Mongo::DB.any_instance.should_receive(:authenticate).never
      MongoMapper.connect('development')
    end

    it "should work without authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      Mongo::Connection.should_receive(:new).with('127.0.0.1', 27017, {})
      MongoMapper.should_receive(:database=).with('test')
      Mongo::DB.any_instance.should_receive(:authenticate).never
      MongoMapper.connect('development')
    end

    it "should work with options" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      connection, logger = mock('connection'), mock('logger')
      Mongo::Connection.should_receive(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      connection, logger = mock('connection'), mock('logger')
      Mongo::Connection.should_receive(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'username' => 'john', 'password' => 'secret'}
      }
      Mongo::DB.any_instance.should_receive(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    it "should work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      Mongo::DB.any_instance.should_receive(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    it "should raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      lambda { MongoMapper.connect('development') }.should raise_error(MongoMapper::InvalidScheme)
    end

    it "should create a replica set connection if config contains multiple hosts" do
      MongoMapper.config = {
        'development' => {
          'hosts' => [ ['127.0.0.1', 27017], ['localhost', 27017] ],
          'database' => 'test'
        }
      }

      Mongo::ReplSetConnection.should_receive(:new).with( ['127.0.0.1', 27017], ['localhost', 27017], {'read_secondary' => true} )
      MongoMapper.should_receive(:database=).with('test')
      Mongo::DB.any_instance.should_receive(:authenticate).never
      MongoMapper.connect('development', 'read_secondary' => true)
    end
  end

  context "setup" do
    it "shouldwork as shortcut for setting config, environment and options" do
      config, logger = mock('config'), mock('logger')
      MongoMapper.should_receive(:config=).with(config)
      MongoMapper.should_receive(:connect).with('development', :logger => logger)
      MongoMapper.should_receive(:handle_passenger_forking).once
      MongoMapper.setup(config, 'development', :logger => logger)
    end
  end
end
