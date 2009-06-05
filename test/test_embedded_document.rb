require 'test_helper'

class EmbeddedDocumentTest < Test::Unit::TestCase
  context "Including MongoMapper::EmbeddedDocument" do
    setup do
      @klass = Class.new do
        include MongoMapper::EmbeddedDocument
      end
    end
        
    should "clear out document default keys" do
      @klass.keys.size.should == 0
    end
  end
  
  context "An instance of an embedded document" do
    setup do
      @document = Class.new do
        include MongoMapper::EmbeddedDocument
        
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
      
      should "be accessible for use in the model" do
        @document.class_eval do
          def name_and_age
            "#{read_attribute(:name)} (#{read_attribute(:age)})"
          end
        end
                
        doc = @document.new(:name => 'John', :age => 27)
        doc.name_and_age.should == 'John (27)'
      end
    end
    
    context "reading an attribute before typcasting" do
      should "work for defined keys" do
        doc = @document.new(:name => 12)
        doc.name_before_typecast.should == 12
      end
      
      should "raise no method error for undefined keys" do
        doc = @document.new
        lambda { doc.foo_before_typecast }.should raise_error(NoMethodError)
      end
      
      should "be accessible for use in a document" do
        @document.class_eval do
          def untypcasted_name
            read_attribute_before_typecast(:name)
          end
        end
                
        doc = @document.new(:name => 12)
        doc.name.should == '12'
        doc.untypcasted_name.should == 12
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
    
    context "respond_to?" do
      setup do
        @doc = @document.new
      end
      
      should "work for readers" do
        @doc.respond_to?(:name).should be_true
        @doc.respond_to?('name').should be_true
      end
      
      should "work for writers" do
        @doc.respond_to?(:name=).should be_true
        @doc.respond_to?('name=').should be_true
      end
      
      should "work for readers before typecast" do
        @doc.respond_to?(:name_before_typecast).should be_true
        @doc.respond_to?('name_before_typecast').should be_true
      end
    end
    
    context "equality" do
      should "be true if all keys and values are equal" do
        doc1 = @document.new(:name => 'John', :age => 27)
        doc2 = @document.new(:name => 'John', :age => 27)
        doc1.should == doc2
      end
      
      should "be false if not all the keys and values are equal" do
        doc1 = @document.new(:name => 'Steve', :age => 27)
        doc2 = @document.new(:name => 'John', :age => 27)
        doc1.should_not == doc2
      end
    end
    
  end # instance of a embedded document
end