require 'test_helper'

class Address; end

class MongoMapperTest < Test::Unit::TestCase
  should "be able to write and read connection" do
    conn = Mongo::MongoClient.new
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end

  should "default connection to new mongo ruby driver" do
    MongoMapper.connection = nil
    MongoMapper.connection.should be_instance_of(Mongo::MongoClient)
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
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults)
      Mongo::DB.any_instance.expects(:issue_authentication).never
      MongoMapper.connect('development')
    end

    should "work without authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults)
      Mongo::DB.any_instance.expects(:issue_authentication).never
      MongoMapper.connect('development')
    end

    should "work with sinatra environment symbol" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults)
      Mongo::DB.any_instance.expects(:issue_authentication).never
      MongoMapper.connect(:development)
    end

    should "work with options" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}            
      connection, logger = mock('connection'), mock('logger')
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults.merge(:logger => logger))
      MongoMapper.connect('development', :logger => logger)
    end

    should "pass along ssl when true" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'ssl' => true}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      connection, logger = mock('connection'), mock('logger')
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults.merge(:logger => logger, :ssl => true))
      MongoMapper.connect('development', :logger => logger)
    end

    should "pass along ssl when false" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'ssl' => false}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      connection, logger = mock('connection'), mock('logger')
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults.merge(:logger => logger, :ssl => false))
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with options from config" do
      MongoMapper.config = {
        'development' => {'host' => '192.168.1.1', 'port' => 2222, 'database' => 'test', 'options' => {'safe' => true}}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      connection, logger = mock('connection'), mock('logger')
      Mongo::MongoClient.expects(:new).with('192.168.1.1', 2222, defaults.merge(:logger => logger, :safe => true))
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true, :auths => []}
      connection, logger = mock('connection'), mock('logger')
      Mongo::MongoClient.expects(:new).with('127.0.0.1', 27017, defaults.merge(:logger => logger))
      MongoMapper.connect('development', :logger => logger)
    end

    should "work with authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'username' => 'john', 'password' => 'secret'}
      }
      Mongo::DB.any_instance.expects(:issue_authentication).with('john', 'secret', false, {:socket => nil})
      MongoMapper.connect('development')
    end

    should "work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      Mongo::DB.any_instance.expects(:issue_authentication).with('john', 'secret', false, {:socket => nil})
      MongoMapper.connect('development')
    end

    should "raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      assert_raises(Mongo::MongoArgumentError) { MongoMapper.connect('development') }
    end

    should "create a replica set connection if config contains multiple hosts in the old format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => [ ['127.0.0.1', 27017], ['localhost', 27017] ],
          'database' => 'test'
        }
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true}
      Mongo::MongoReplicaSetClient.expects(:new).with( ['127.0.0.1:27017', 'localhost:27017'], defaults.merge('read_secondary' => true) )
      Mongo::DB.any_instance.expects(:issue_authentication).never
      MongoMapper.connect('development', 'read_secondary' => true)
    end

    should "create a replica set connection if config contains multiple hosts in the new format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => ['127.0.0.1:27017', 'localhost:27017'],
          'database' => 'test'
        }
      }
      defaults = {:wtimeout => nil, :j => nil, :fsync => nil, :connect => true}
      Mongo::MongoReplicaSetClient.expects(:new).with( ['127.0.0.1:27017', 'localhost:27017'], defaults.merge('read_secondary' => true) )
      Mongo::DB.any_instance.expects(:issue_authentication).never
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
