require 'test_helper'

class DocumentTest < Test::Unit::TestCase
  context "The Document Class" do
    setup do
      @document = Class.new
      @document.instance_eval { include MongoMapper::Document }
    end

    should "should be able to define a key" do
      key = @document.key(:name, String)
      key.name.should == 'name'
      key.type.should == String
      key.should be_instance_of(MongoMapper::Key)
    end
      
    should "know what keys have been defined" do
      @document.key(:name, String)
      @document.key(:age, Integer)
      @document.keys.size.should == 2
      @document.keys['name'].name.should == 'name'
      @document.keys['name'].type.should == String
      @document.keys['age'].name.should == 'age'
      @document.keys['age'].type.should == Integer
    end
  end # Document class
  
  context "An instance of a document" do
    setup do
      @document = Class.new
      @document.instance_eval do
        include MongoMapper::Document
        
        key :name, String
        key :age, Integer
      end
    end
    
    context "when initialized" do
      should "accept a hash that sets keys and values" do
        doc = @document.new(:name => 'John', :age => 23)
        doc.keys.should == {'name' => 'John', 'age' => 23}
      end
      
      should "silently reject keys that have not been defined" do
        doc = @document.new(:foobar => 'baz')
        doc.keys.should == {}
      end
    end
    
    context "mass assigning keys" do
      should "update values for keys provided" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.keys = {:name => 'new value', :age => 5}
        doc.keys[:name].should == 'new value'
        doc.keys[:age].should == 5
      end
      
      should "not update values for keys that were not provided" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.keys = {:name => 'new value'}
        doc.keys[:name].should == 'new value'
        doc.keys[:age].should == 10
      end
      
      should "ignore keys that do not exist" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.keys = {:name => 'new value', :foobar => 'baz'}
        doc.keys[:name].should == 'new value'
        doc.keys[:foobar].should be(nil)
      end
    end
    
    context "requesting keys" do
      should "default to empty hash" do
        doc = @document.new
        doc.keys.should == {}
      end
      
      should "return all keys with a value" do
        doc = @document.new(:name => 'string')
        doc.keys.should == {'name' => 'string'}
      end
    end
    
    context "shorcuts" do
      should "be able to read key with []" do
        doc = @document.new(:name => 'string')
        doc[:name].should == 'string'
      end
      
      should "be able to assign key value with []=" do
        doc = @document.new
        doc[:name] = 'string'
        doc[:name].should == 'string'
      end
    end
    
    context "indifferent access" do
      should "be enabled for keys" do
        doc = @document.new(:name => 'string')
        doc.keys[:name].should == 'string'
        doc.keys['name'].should == 'string'
      end
    end
    
    context "getters" do
      should "work for defined keys" do
        doc = @document.new(:name => 'string')
        doc.name.should == 'string'
      end
      
      should "raise no method error for undefined keys" do
        doc = @document.new
        lambda { doc.fart }.should raise_error(NoMethodError)
      end
    end
    
    context "setters" do
      should "work for defined keys" do
        doc = @document.new
        doc.name = 'John'
        doc.name.should == 'John'
      end
      
      should "raise no method error for undefined keys" do
        doc = @document.new
        lambda { doc.fart = 'poof!' }.should raise_error(NoMethodError)
      end
      
      should "typecast value" do
        doc = @document.new
        doc.name = 1234
        doc.name.should == '1234'
        doc.age = '21'
        doc.age.should == 21
      end
    end
    
  end # instance of a document
end # DocumentTest
