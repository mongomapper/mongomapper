require 'test_helper'

class MongoMapperTest < Test::Unit::TestCase
  include XGen::Mongo::Driver
  
  should "have connection" do
    MongoMapper.connection.should be_instance_of(Mongo)
  end
  
  should "be able to set connection information" do
    conn = Mongo.new('localhost', 3000)
    MongoMapper.connection = conn
    MongoMapper.connection.should == conn
  end
end
