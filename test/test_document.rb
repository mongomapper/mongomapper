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
    
    should "be able to define timestamps with timestamp shortcut" do
      @document.timestamp
      @document.keys.keys.should include('created_at')
      @document.keys.keys.should include('updated_at')
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
        doc.attributes.should == {'name' => 'John', 'age' => 23}
      end
      
      should "silently reject keys that have not been defined" do
        doc = @document.new(:foobar => 'baz')
        doc.attributes.should == {}
      end
    end
    
    context "mass assigning keys" do
      should "update values for keys provided" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.attributes = {:name => 'new value', :age => 5}
        doc.attributes[:name].should == 'new value'
        doc.attributes[:age].should == 5
      end

      should "not update values for keys that were not provided" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.attributes = {:name => 'new value'}
        doc.attributes[:name].should == 'new value'
        doc.attributes[:age].should == 10
      end

      should "ignore keys that do not exist" do
        doc = @document.new(:name => 'foobar', :age => 10)
        doc.attributes = {:name => 'new value', :foobar => 'baz'}
        doc.attributes[:name].should == 'new value'
        doc.attributes[:foobar].should be(nil)
      end

      should "typecast key values" do
        doc = @document.new(:name => 1234, :age => '21')
        doc.name.should == '1234'
        doc.age.should == 21
      end
    end

    context "requesting keys" do
      should "default to empty hash" do
        doc = @document.new
        doc.attributes.should == {}
      end

      should "return all keys that aren't nil" do
        doc = @document.new(:name => 'string', :age => nil)
        doc.attributes.should == {'name' => 'string'}
      end
    end

    context "key shorcuts" do
      should "be able to read key with []" do
        doc = @document.new(:name => 'string')
        doc[:name].should == 'string'
      end

      should "be able to write key value with []=" do
        doc = @document.new
        doc[:name] = 'string'
        doc[:name].should == 'string'
      end
    end

    context "indifferent access" do
      should "be enabled for keys" do
        doc = @document.new(:name => 'string')
        doc.attributes[:name].should == 'string'
        doc.attributes['name'].should == 'string'
      end
    end

    context "reading an attribute" do
      should "work for defined keys" do
        doc = @document.new(:name => 'string')
        doc.name.should == 'string'
      end

      should "raise no method error for undefined keys" do
        doc = @document.new
        lambda { doc.fart }.should raise_error(NoMethodError)
      end
      
      should "know if reader defined" do
        doc = @document.new
        doc.reader?('name').should be(true)
        doc.reader?(:name).should be(true)
        doc.reader?('age').should be(true)
        doc.reader?(:age).should be(true)
        doc.reader?('foobar').should be(false)
        doc.reader?(:foobar).should be(false)
      end
      
      should "be accissible for use in the model" do
        @document.class_eval do
          def name_and_age
            "#{read_attribute(:name)} (#{read_attribute(:age)})"
          end
        end
                
        doc = @document.new(:name => 'John', :age => 27)
        doc.name_and_age.should == 'John (27)'
      end
    end

    context "writing an attribute" do
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
      
      should "know if writer defined" do
        doc = @document.new
        doc.writer?('name').should be(true)
        doc.writer?('name=').should be(true)
        doc.writer?(:name).should be(true)
        doc.writer?('age').should be(true)
        doc.writer?('age=').should be(true)
        doc.writer?(:age).should be(true)
        doc.writer?('foobar').should be(false)
        doc.writer?('foobar=').should be(false)
        doc.writer?(:foobar).should be(false)
      end
      
      should "be accessible for use in the model" do
        @document.class_eval do          
          def name_and_age=(new_value)
            new_value.match(/([^\(\s]+) \((.*)\)/)
            write_attribute :name, $1
            write_attribute :age, $2
          end
        end
                
        doc = @document.new
        doc.name_and_age = 'Frank (62)'
        doc.name.should == 'Frank'
        doc.age.should == 62
      end
    end # writing an attribute    
    
    context "with timestamps defined" do
      should_eventually "set created_at and updated_at on create" do
        
      end
      
      should_eventually "set updated_at on update" do
        
      end
    end
    
  end # instance of a document
end # DocumentTest
