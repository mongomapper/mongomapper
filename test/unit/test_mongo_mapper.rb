require 'test_helper'

class Address; end

class MongoMapperTest < Test::Unit::TestCase
  should "be able to write and read connection" do
    conn = Mongo::Connection.new
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end

  should "default connection to new mongo ruby driver" do
    MongoMapper.connection = nil
    MongoMapper.connection.should be_instance_of(Mongo::Connection)
  end

  should "be able to write and read default database" do
    MongoMapper.database = 'test'
    MongoMapper.database.should be_instance_of(Mongo::DB)
    MongoMapper.database.name.should == 'test'
  end

  should "have document not found error" do
    lambda {
      MongoMapper::DocumentNotFound
    }.should_not raise_error
  end

  should "be able to read/write config" do
    config = {
      'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'},
      'production'  => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test-prod'}
    }
    MongoMapper.config = config
    MongoMapper.config.should == config
  end

  context "connecting to environment from config" do
    should "work without authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      Mongo::Connection.expects(:new).with('127.0.0.1', 27017, {})
      MongoMapper.expects(:database=).with('test')
      Mongo::DB.any_instance.expects(:authenticate).never
      MongoMapper.connect('development')
    end

    should "work without authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      Mongo::Connection.expects(:new).with('127.0.0.1', 27017, {})
      MongoMapper.expects(:database=).with('test')
      Mongo::DB.any_instance.expects(:authenticate).never
      MongoMapper.connect('development')
    end

    should "work with sinatra environment symbol" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      Mongo::Connection.expects(:new).with('127.0.0.1', 27017, {})
      MongoMapper.expects(:database=).with('test')
      Mongo::DB.any_instance.expects(:authenticate).never
      MongoMapper.connect(:development)
    end

    should "work with options" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      connection, logger = mock('connection'), mock('logger')
      Mongo::Connection.expects(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with options from config" do
      MongoMapper.config = {
        'development' => {'host' => '192.168.1.1', 'port' => 2222, 'database' => 'test', 'options' => {'safe' => true}}
      }
      connection, logger = mock('connection'), mock('logger')
      Mongo::Connection.expects(:new).with('192.168.1.1', 2222, :logger => logger, :safe => true)
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      connection, logger = mock('connection'), mock('logger')
      Mongo::Connection.expects(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'username' => 'john', 'password' => 'secret'}
      }
      Mongo::DB.any_instance.expects(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    should "work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      Mongo::DB.any_instance.expects(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    should "raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      assert_raises(MongoMapper::InvalidScheme) { MongoMapper.connect('development') }
    end

    should "create a replica set connection if config contains multiple hosts in the old format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => [ ['127.0.0.1', 27017], ['localhost', 27017] ],
          'database' => 'test'
        }
      }

      Mongo::ReplSetConnection.expects(:new).with( ['127.0.0.1', 27017], ['localhost', 27017], {'read_secondary' => true} )
      MongoMapper.expects(:database=).with('test')
      Mongo::DB.any_instance.expects(:authenticate).never
      MongoMapper.connect('development', 'read_secondary' => true)
    end

    should "create a replica set connection if config contains multiple hosts in the new format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => ['127.0.0.1:27017', 'localhost:27017'],
          'database' => 'test'
        }
      }

      Mongo::ReplSetConnection.expects(:new).with( ['127.0.0.1:27017', 'localhost:27017'], {'read_secondary' => true} )
      MongoMapper.expects(:database=).with('test')
      Mongo::DB.any_instance.expects(:authenticate).never
      MongoMapper.connect('development', 'read_secondary' => true)
    end
  end

  context "setup" do
    should "work as shortcut for setting config, environment and options" do
      config, logger = mock('config'), mock('logger')
      MongoMapper.expects(:config=).with(config)
      MongoMapper.expects(:connect).with('development', :logger => logger)
      MongoMapper.expects(:handle_passenger_forking).once
      MongoMapper.setup(config, 'development', :logger => logger)
    end
  end
end
