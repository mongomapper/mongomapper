require 'test_helper'

class Address
  include MongoMapper::SubDocument
  
  key :address, String
  key :city,    String
  key :state,   String
  key :zip,     Integer
end

class KeyTest < Test::Unit::TestCase
  include MongoMapper
  
  context "The Key Class" do
    should "have the native types defined" do
      Key::NativeTypes.should == [String, Float, Time, Date, Integer, Boolean, Array, Hash]
    end
  end
  
  context "Initializing a new key" do
    should "allow setting the name" do
      Key.new(:foo, String).name.should == 'foo'
    end
    
    should "allow setting the type" do
      Key.new(:foo, Integer).type.should be(Integer)
    end
    
    should "allow setting options" do
      Key.new(:foo, Integer, :required => true).options[:required].should be(true)
    end
    
    should "symbolize option keys" do
      Key.new(:foo, Integer, 'required' => true).options[:required].should be(true)
    end
  end
  
  context "A key" do
    should "be equal to another key with same name and type" do
      Key.new(:name, String).should == Key.new(:name, String)
    end
    
    should "not be equal to another key with different name" do
      Key.new(:name, String).should_not == Key.new(:foo, String)
    end
    
    should "not be equal to another key with different type" do
      Key.new(:name, String).should_not == Key.new(:name, Integer)
    end
    
    should "know if it is native" do
      Key.new(:name, String).native?.should be_true
    end
    
    should "know if it is not native" do
      klass = Class.new
      Key.new(:name, klass).native?.should be_false
    end
    
    should "know if it is a subdocument" do
      klass = Class.new do
        include MongoMapper::SubDocument
      end
      Key.new(:name, klass).subdocument?.should be_true
    end
    
    should "know if it is not a subdocument" do
      Key.new(:name, String).subdocument?.should be_false
    end
  end
  
  context "setting a value" do
    should "correctly typecast Strings" do
      key = Key.new(:foo, String)
      [21, '21'].each do |a|
        key.set(a).should == '21'
      end
    end

    should "correctly typecast Integers" do
      key = Key.new(:foo, Integer)
      [21, 21.0, '21'].each do |a|
        key.set(a).should == 21
      end
    end

    should "correctly typecast Floats" do
      key = Key.new(:foo, Float)
      [21, 21.0, '21'].each do |a|
        key.set(a).should == 21.0
      end
    end

    should "correctly typecast Times" do
      key = Key.new(:foo, Time)
      key.set('2000-01-01 01:01:01.123456').should == Time.local(2000, 1, 1, 1, 1, 1, 123456)
    end

    should "correctly typecast Dates" do
      key = Key.new(:foo, Date)
      key.set('2000-01-01').should == Date.new(2000, 1, 1)
    end
    
    should "correctly typecast Boolean" do
      key = Key.new(:foo, Boolean)
      ['false', false, 'f', '0', 0].each do |b|
        key.set(b).should == false
      end
      
      ['true', true, 't', '1', 1].each do |b|
        key.set(b).should == true
      end
    end
    
    should "correctly typecast Array" do
      key = Key.new(:foo, Array)
      key.set([1,2,3,4]).should == [1,2,3,4]
      key.set({'1' => '2', '3' => '4'}).should == [['1', '2'], ['3', '4']]
      key.set('1').should == ['1']
    end
    
    should "correctly typecast Hash using indifferent access" do
      key = Key.new(:foo, Hash)
      key.set(:foo => 'bar')[:foo].should == 'bar'
      key.set(:foo => 'bar')['foo'].should == 'bar'
      key.set(:foo => {:bar => 'baz'})[:foo][:bar].should == 'baz'
      key.set(:foo => {:bar => 'baz'})['foo']['bar'].should == 'baz'
    end
  end
  
  context "getting a value" do
    should "work" do
      key = Key.new(:foo, String)
      key.get('bar').should == 'bar'
    end
    
    context "for an array" do
      should "return array" do
        key = Key.new(:foo, Array)
        key.get([1,2]).should == [1,2]
      end
      
      should "default to empty array" do
        key = Key.new(:foo, Array)
        key.get(nil).should == []
      end
    end
    
    context "for a hash" do
      should "default to empty hash" do
        key = Key.new(:foo, Hash)
        key.get(nil).should == {}
      end

      should "use hash with indifferent access" do
        key = Key.new(:foo, Hash)
        key.get({:foo => 'bar'})['foo'].should == 'bar'
        key.get({:foo => 'bar'})[:foo].should == 'bar'
      end
    end
    
    context "for a subdocument" do
      should "default to nil" do        
        key = Key.new(:foo, Address)
        key.get(nil).should be_nil
      end
      
      should "return instance if instance" do
        address = Address.new(:city => 'South Bend', :state => 'IN', :zip => 46544)
        key = Key.new(:foo, Address)
        key.get(address).should == address
      end
    end
  end
  
end # KeyTest
