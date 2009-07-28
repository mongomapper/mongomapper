require 'test_helper'

class MongoIDTest < Test::Unit::TestCase
  PhonyError = Class.new(StandardError)
  
  class Phony
    def to_s
      raise PhonyError
    end
  end
  
  context "mm_typecast" do
    should "return value if object id" do
      id = XGen::Mongo::Driver::ObjectID.new
      MongoID.mm_typecast(id).should == id
    end
    
    should "return object id if string" do
      id = XGen::Mongo::Driver::ObjectID.new
      MongoID.mm_typecast(id.to_s).should == id
    end
    
    should "raise DocumentNotFound if invalid id" do
      lambda {
        MongoID.mm_typecast(1234)
      }.should raise_error(MongoMapper::DocumentNotFound)
    end
    
    should "raise exception if message does not match illegal object id" do
      lambda {
        MongoID.mm_typecast(Phony.new)
      }.should raise_error(PhonyError)
    end
  end
end