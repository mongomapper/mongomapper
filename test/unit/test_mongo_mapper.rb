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

    should "work with options" do
      MongoMapper.config = {
        'development' => {'host' => '127.0.0.1', 'port' => 27017, 'database' => 'test'}
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
  end

  context "setup" do
    should "work as shortcut for setting config, environment and options" do
      config, logger = mock('config'), mock('logger')
      MongoMapper.expects(:config=).with(config)
      MongoMapper.expects(:connect).with('development', :logger => logger)
      MongoMapper.expects(:handle_passenger_forking).never
      MongoMapper.setup(config, 'development', :logger => logger)
    end
    
    should "handle passenger if option present" do
      config, logger = mock('config'), mock('logger')
      MongoMapper.expects(:config=).with(config)
      MongoMapper.expects(:connect).with('development', :logger => logger)
      MongoMapper.expects(:handle_passenger_forking)
      MongoMapper.setup(config, 'development', :logger => logger, :passenger => true)
    end
  end
  

  context "use_time_zone?" do
    should "be true if Time.zone set" do
      Time.zone = 'Hawaii'
      MongoMapper.use_time_zone?.should be_true
      Time.zone = nil
    end

    should "be false if Time.zone not set" do
      MongoMapper.use_time_zone?.should be_false
    end
  end

  context "time_class" do
    should "be Time.zone if using time zones" do
      Time.zone = 'Hawaii'
      MongoMapper.time_class.should == Time.zone
      Time.zone = nil
    end

    should "be Time if not using time zones" do
      MongoMapper.time_class.should == Time
    end
  end

  context "normalize_object_id" do
    should "turn string into object id" do
      id = Mongo::ObjectID.new
      MongoMapper.normalize_object_id(id.to_s).should == id
    end

    should "leave object id alone" do
      id = Mongo::ObjectID.new
      MongoMapper.normalize_object_id(id).should == id
    end
  end
end
