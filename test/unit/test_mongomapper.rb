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
    MongoMapper.database = DefaultDatabase
    MongoMapper.database.should be_instance_of(Mongo::DB)
    MongoMapper.database.name.should == DefaultDatabase
  end
  
  should "have document not found error" do
    lambda {
      MongoMapper::DocumentNotFound
    }.should_not raise_error
  end
end
