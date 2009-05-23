require 'test_helper'

class KeyTest < Test::Unit::TestCase
  context "The Key Class" do
    should "have the native types defined" do
      MongoMapper::Key::NativeTypes.should == [String, Float, Time, Date, DateTime, Integer, Boolean]
    end
  end
  
  context "Initializing a new key" do
    should "allow setting the name" do
      MongoMapper::Key.new(:foo, String).name.should == 'foo'
    end
    
    should "allow setting the type" do
      MongoMapper::Key.new(:foo, Integer).type.should be(Integer)
    end
  end
  
  context "A key" do
    should "be equal to another key with same name and type" do
      MongoMapper::Key.new(:name, String).should == MongoMapper::Key.new(:name, String)
    end
    
    should "not be equal to another key with different name" do
      MongoMapper::Key.new(:name, String).should_not == MongoMapper::Key.new(:foo, String)
    end
    
    should "not be equal to another key with different type" do
      MongoMapper::Key.new(:name, String).should_not == MongoMapper::Key.new(:name, Integer)
    end
  end
  
end
