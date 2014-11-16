require 'spec_helper'

class Address; end

describe "MongoMapper" do
  it "should be able to write and read connection" do
    conn = Mongo::MongoClient.new
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end

  it "should default connection to new mongo ruby driver" do
    MongoMapper.connection = nil
    MongoMapper.connection.should be_instance_of(Mongo::MongoClient)
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
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, {})
      expect(MongoMapper).to receive(:database=).with('test')
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).never
      MongoMapper.connect('development')
    end

    it "should work without authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, {})
      expect(MongoMapper).to receive(:database=).with('test')
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).never
      MongoMapper.connect('development')
    end

    it "should work with sinatra environment symbol" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, {})
      expect(MongoMapper).to receive(:database=).with('test')
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).never
      MongoMapper.connect(:development)
    end

    it "should work with options" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should pass along ssl when true" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'ssl' => true}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, :logger => logger, :ssl => true)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should pass along ssl when false" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'ssl' => false}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, :logger => logger, :ssl => false)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should convert read preferences to symbols" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'options' =>  {'read' => 'primary'}}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, :logger => logger, :read => :primary)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options from config" do
      MongoMapper.config = {
        'development' => {'host' => '192.168.1.1', 'port' => 2222, 'database' => 'test', 'options' => {'safe' => true}}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('192.168.1.1', 2222, :logger => logger, :safe => true)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with options using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://127.0.0.1:27017/test'}
      }
      connection, logger = double('connection'), double('logger')
      expect(Mongo::MongoClient).to receive(:new).with('127.0.0.1', 27017, :logger => logger)
      MongoMapper.connect('development', :logger => logger)
    end

    it "should work with authentication" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test', 'username' => 'john', 'password' => 'secret'}
      }
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    it "should work with authentication using uri" do
      MongoMapper.config = {
        'development' => {'uri' => 'mongodb://john:secret@127.0.0.1:27017/test'}
      }
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).with('john', 'secret')
      MongoMapper.connect('development')
    end

    it "should raise error for invalid scheme" do
      MongoMapper.config = {
        'development' => {'uri' => 'mysql://127.0.0.1:5336/foo'}
      }
      expect { MongoMapper.connect('development') }.to raise_error(MongoMapper::InvalidScheme)
    end

    it "should create a replica set connection if config contains multiple hosts in the old format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => [ ['127.0.0.1', 27017], ['localhost', 27017] ],
          'database' => 'test'
        }
      }

      expect(Mongo::MongoReplicaSetClient).to receive(:new).with( ['127.0.0.1', 27017], ['localhost', 27017], {'read_secondary' => true} )
      expect(MongoMapper).to receive(:database=).with('test')
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).never
      MongoMapper.connect('development', 'read_secondary' => true)
    end

    it "should create a replica set connection if config contains multiple hosts in the new format" do
      MongoMapper.config = {
        'development' => {
          'hosts' => ['127.0.0.1:27017', 'localhost:27017'],
          'database' => 'test'
        }
      }

      expect(Mongo::MongoReplicaSetClient).to receive(:new).with( ['127.0.0.1:27017', 'localhost:27017'], {'read_secondary' => true} )
      expect(MongoMapper).to receive(:database=).with('test')
      expect_any_instance_of(Mongo::DB).to receive(:authenticate).never
      MongoMapper.connect('development', 'read_secondary' => true)
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
