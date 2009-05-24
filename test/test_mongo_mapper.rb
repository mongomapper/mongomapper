require 'test_helper'

class MongoMapperTest < Test::Unit::TestCase
  should "have connection" do
    MongoMapper.connection.should be_instance_of(XGen::Mongo::Driver::Mongo)
  end
  
  should "be able to set connection information" do
    conn = XGen::Mongo::Driver::Mongo.new
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end
  
  should "be able to write and read default database" do
    MongoMapper.default_database = 'mongo_mapper_test'
    MongoMapper.default_database.should be_instance_of(XGen::Mongo::Driver::DB)
    MongoMapper.default_database.name.should == 'mongo_mapper_test'
  end
end
