require 'test_helper'

class Grandparent
  include MongoMapper::EmbeddedDocument
  key :grandparent, String
end

class Parent < Grandparent
  include MongoMapper::EmbeddedDocument
  key :parent, String
end

class Child < Parent
  include MongoMapper::EmbeddedDocument
  key :child, String
end

class OtherChild < Parent
  include MongoMapper::EmbeddedDocument
  key :other_child, String
end

class EmbeddedDocumentTest < Test::Unit::TestCase
  context "Including MongoMapper::EmbeddedDocument" do
    setup do
      @klass = Class.new do
        include MongoMapper::EmbeddedDocument
      end
    end
    
    should "add _id key" do
      @klass.keys['_id'].should_not be_nil
    end
  end
  
  context "parent_model" do
    should "be nil if none of parents ancestors include EmbeddedDocument" do
      parent = Class.new
      document = Class.new(parent) do
        include MongoMapper::EmbeddedDocument
      end
      document.parent_model.should be_nil
    end
    
    should "find parent" do
      Parent.parent_model.should == Grandparent
      Child.parent_model.should == Parent
    end
  end
  
  context "defining a key" do
    setup do
      @document = Class.new do
        include MongoMapper::EmbeddedDocument
      end
    end
    
    should "work" do
      key = @document.key(:name, String)
      key.name.should == 'name'
      key.type.should == String
      key.should be_instance_of(MongoMapper::Key)
    end
    
    should "work with options" do
      key = @document.key(:name, String, :required => true)
      key.options[:required].should be(true)
    end
    
    should "be tracked per document" do
      @document.key(:name, String)
      @document.key(:age, Integer)
      @document.keys['name'].name.should == 'name'
      @document.keys['name'].type.should == String
      @document.keys['age'].name.should == 'age'
      @document.keys['age'].type.should == Integer
    end
    
    should "be redefinable" do
      @document.key(:foo, String)
      @document.keys['foo'].type.should == String
      @document.key(:foo, Integer)
      @document.keys['foo'].type.should == Integer
    end
    
    should "create reader method" do
      @document.new.should_not respond_to(:foo)
      @document.key(:foo, String)
      @document.new.should respond_to(:foo)
    end
    
    should "create reader before typecast method" do
      @document.new.should_not respond_to(:foo_before_typecast)
      @document.key(:foo, String)
      @document.new.should respond_to(:foo_before_typecast)
    end
    
    should "create writer method" do
      @document.new.should_not respond_to(:foo=)
      @document.key(:foo, String)
      @document.new.should respond_to(:foo=)
    end
    
    should "create boolean method" do
      @document.new.should_not respond_to(:foo?)
      @document.key(:foo, String)
      @document.new.should respond_to(:foo?)
    end
  end
  
  context "keys" do
    should "be inherited" do
      Grandparent.keys.keys.sort.should == ['_id', 'grandparent']
      Parent.keys.keys.sort.should == ['_id', 'grandparent', 'parent']
      Child.keys.keys.sort.should  == ['_id', 'child', 'grandparent', 'parent']
    end
    
    should "propogate to subclasses if key added after class definition" do
      Grandparent.key :_type, String
      
      Grandparent.keys.keys.sort.should == ['_id', '_type', 'grandparent']
      Parent.keys.keys.sort.should      == ['_id', '_type', 'grandparent', 'parent']
      Child.keys.keys.sort.should       == ['_id', '_type', 'child', 'grandparent', 'parent']
    end
  end
  
  context "subclasses" do
    should "default to nil" do
      Child.subclasses.should be_nil
    end
    
    should "be recorded" do
      Grandparent.subclasses.should == [Parent]
      Parent.subclasses.should      == [Child, OtherChild]
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
    
    should "automatically have an _id key" do
      @document.keys.keys.should include('_id')
    end
    
    should "have id method that sets _id" do
      doc = @document.new
      doc.id.should == doc._id.to_s
    end
    
    context "setting custom id" do
      should "set _id" do
        doc = @document.new(:id => '1234')
        doc._id.should == '1234'
      end
      
      should "know that custom id is set" do
        doc = @document.new
        doc.using_custom_id?.should be_false
        doc.id = '1234'
        doc.using_custom_id?.should be_true
      end
    end

    context "being initialized" do
      should "accept a hash that sets keys and values" do
        doc = @document.new(:name => 'John', :age => 23)
        doc.attributes.keys.sort.should == ['_id', 'age', 'name']
        doc.attributes['name'].should == 'John'
        doc.attributes['age'].should == 23
      end

      should "not throw error if initialized with nil" do
        lambda {
          @document.new(nil)
        }.should_not raise_error
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

      should "not ignore keys that have methods defined" do
        @document.class_eval do
          attr_writer :password

          def passwd
            @password
          end
        end

        doc = @document.new(:name => 'foobar', :password => 'secret')
        doc.passwd.should == 'secret'
      end

      should "typecast key values" do
        doc = @document.new(:name => 1234, :age => '21')
        doc.name.should == '1234'
        doc.age.should == 21
      end
    end

    context "attributes" do
      should "default to hash with _id" do
        doc = @document.new
        doc.attributes.keys.should == ['_id']
      end

      should "return all keys that aren't nil" do
        doc = @document.new(:name => 'string', :age => nil)
        doc.attributes.keys.sort.should == ['_id', 'name']
        doc.attributes.values.should include('string')
      end
    end
    
    context "key shorcut access" do
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

      should "be accessible for use in the model" do
        @document.class_eval do
          def name_and_age
            "#{read_attribute(:name)} (#{read_attribute(:age)})"
          end
        end

        doc = @document.new(:name => 'John', :age => 27)
        doc.name_and_age.should == 'John (27)'
      end
      
      should "set instance variable" do
        @document.key :foo, Array
        doc = @document.new
        doc.instance_variable_get("@foo").should be_nil
        doc.foo
        doc.instance_variable_get("@foo").should == []
      end
      
      should "not set instance variable if frozen" do
        @document.key :foo, Array
        doc = @document.new
        doc.instance_variable_get("@foo").should be_nil
        doc.freeze
        doc.foo
        doc.instance_variable_get("@foo").should be_nil
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
    
    context "checking if an attributes value is present" do
      should "work for defined keys" do
        doc = @document.new
        doc.name?.should be_false
        doc.name = 'John'
        doc.name?.should be_true
      end
      
      should "raise no method error for undefined keys" do
        doc = @document.new
        lambda { doc.fart? }.should raise_error(NoMethodError)
      end
    end
    
    context "equality" do
      should "be equal if id and class are the same" do
        (@document.new('_id' => 1) == @document.new('_id' => 1)).should be(true)
      end

      should "not be equal if class same but id different" do
        (@document.new('_id' => 1) == @document.new('_id' => 2)).should be(false)
      end

      should "not be equal if id same but class different" do
        @another_document = Class.new do
          include MongoMapper::Document
        end

        (@document.new('_id' => 1) == @another_document.new('_id' => 1)).should be(false)
      end
    end
  end # instance of a embedded document
end
