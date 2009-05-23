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
      @document.keys[0].name.should == 'name'
      @document.keys[1].name.should == 'age'
      @document.keys[1].type.should == Integer
    end
  end # Document class
  
  context "An instance of a document" do
    setup do
      @document = Class.new
      @document.instance_eval do
        include MongoMapper::Document
        
        key :string, String
        key :integer, Integer
      end
    end
    
    context "when initialized" do
      should "accept a hash that sets keys and values" do
        doc = @document.new(:string => 'John', :integer => 23)
        doc.keys.should == {'string' => 'John', 'integer' => 23}
      end
      
      should "silently reject keys that have not been defined" do
        doc = @document.new(:foobar => 'baz')
        doc.keys.should == {}
      end
    end
    
    context "mass assigning keys" do
      should "update values for keys provided" do
        doc = @document.new(:string => 'foobar', :integer => 10)
        doc.keys = {:string => 'new value', :integer => 5}
        doc.keys[:string].should == 'new value'
        doc.keys[:integer].should == 5
      end
      
      should "not update values for keys that were not provided" do
        doc = @document.new(:string => 'foobar', :integer => 10)
        doc.keys = {:string => 'new value'}
        doc.keys[:string].should == 'new value'
        doc.keys[:integer].should == 10
      end
      
      should "ignore keys that do not exist" do
        doc = @document.new(:string => 'foobar', :integer => 10)
        doc.keys = {:string => 'new value', :foobar => 'baz'}
        doc.keys[:string].should == 'new value'
        doc.keys[:foobar].should be(nil)
      end
    end
    
    context "requesting keys" do
      should "default to empty hash" do
        doc = @document.new
        doc.keys.should == {}
      end
      
      should "return all keys with a value" do
        doc = @document.new(:string => 'string')
        doc.keys.should == {'string' => 'string'}
      end
    end
    
    context "shorcuts" do
      should "be able to read key with []" do
        doc = @document.new(:string => 'string')
        doc[:string].should == 'string'
      end
      
      should "be able to assign key value with []=" do
        doc = @document.new
        doc[:string] = 'string'
        doc[:string].should == 'string'
      end
    end
    
    context "indifferent access" do
      should "be enabled for keys" do
        doc = @document.new(:string => 'string')
        doc.keys[:string].should == 'string'
        doc.keys['string'].should == 'string'
      end
    end
    
  end # instance of a document
end # DocumentTest
