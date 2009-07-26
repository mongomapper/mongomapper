require 'test_helper'

class DocumentTest < Test::Unit::TestCase
  context "The Document Class" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
      end
    end

    should "track its descendants" do
      MongoMapper::Document.descendants.should include(@document)
    end

    should "use default database by default" do
      @document.database.should == MongoMapper.database
    end

    should "have a connection" do
      @document.connection.should be_instance_of(XGen::Mongo::Driver::Mongo)
    end

    should "allow setting different connection without affecting the default" do
      conn = XGen::Mongo::Driver::Mongo.new
      @document.connection conn
      @document.connection.should == conn
      @document.connection.should_not == MongoMapper.connection
    end

    should "allow setting a different database without affecting the default" do
      @document.database AlternateDatabase
      @document.database.name.should == AlternateDatabase

      another_document = Class.new do
        include MongoMapper::Document
      end
      another_document.database.should == MongoMapper.database
    end
    
    should "default collection name to class name tableized" do
      class Item
        include MongoMapper::Document
      end
      
      Item.collection.should be_instance_of(XGen::Mongo::Driver::Collection)
      Item.collection.name.should == 'items'
    end

    should "allow setting the collection name" do
      @document.collection('foobar')
      @document.collection.should be_instance_of(XGen::Mongo::Driver::Collection)
      @document.collection.name.should == 'foobar'
    end
  end # Document class

  context "An instance of a document" do
    setup do
      @document = Class.new do
        include MongoMapper::Document

        key :name, String
        key :age, Integer
      end
      @document.collection.clear
    end

    should "have access to the class's collection" do
      doc = @document.new
      doc.collection.should == @document.collection
    end

    should "automatically have an _id key" do
      @document.keys.keys.should include('_id')
    end

    should "automatically have a created_at key" do
      @document.keys.keys.should include('created_at')
    end

    should "automatically have an updated_at key" do
      @document.keys.keys.should include('updated_at')
    end

    should "use default values if defined for keys" do
      @document.key :active, Boolean, :default => true

      @document.new.active.should be_true
      @document.new(:active => false).active.should be_false
    end

    context "new?" do
      should "be true if no id" do
        @document.new.new?.should be(true)
      end

      should "be true if has id but id not in database" do
        @document.new('_id' => 1).new?.should be(true)
      end

      should "be false if has id and id is in database" do
        doc = @document.create(:name => 'John Nunemaker', :age => 27)
        doc.new?.should be(false)
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
  end # instance of a document
end # DocumentTest
