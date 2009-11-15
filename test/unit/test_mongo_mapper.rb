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
end
