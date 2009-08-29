require 'test_helper'
require 'models'

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
      @document.connection.should be_instance_of(Mongo::Connection)
    end

    should "allow setting different connection without affecting the default" do
      conn = Mongo::Connection.new
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
      
      Item.collection.should be_instance_of(Mongo::Collection)
      Item.collection.name.should == 'items'
    end

    should "allow setting the collection name" do
      @document.collection('foobar')
      @document.collection.should be_instance_of(Mongo::Collection)
      @document.collection.name.should == 'foobar'
    end
  end # Document class
  
  context "Documents that inherit from other documents" do
    should "default collection to inherited class" do
      Message.collection.name.should == 'messages'
      Enter.collection.name.should   == 'messages'
      Exit.collection.name.should    == 'messages'
      Chat.collection.name.should    == 'messages'
    end
    
    should "track subclasses" do
      Message.subclasses.should == [Enter, Exit, Chat]
    end
  end

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

    should "use default values if defined for keys" do
      @document.key :active, Boolean, :default => true

      @document.new.active.should be_true
      @document.new(:active => false).active.should be_false
    end

    context "new?" do
      should "be true if no id" do
        @document.new.new?.should be_true
      end
      
      should "be true if id but using custom id and not saved yet" do
        doc = @document.new
        doc.id = '1234'
        doc.new?.should be_true
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
