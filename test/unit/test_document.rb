require 'test_helper'
require 'models'

class DocumentTest < Test::Unit::TestCase
  context "The Document Class" do
    setup do
      @document = Doc()
    end
    
    should "return false for embeddable" do
      Doc().embeddable?.should be_false
    end
    
    should "have logger method" do
      @document.logger.should == MongoMapper.logger
      @document.logger.should be_instance_of(Logger)
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
      @document.set_database_name 'test2'
      @document.database_name.should == 'test2'
      @document.database.name.should == 'test2'

      another_document = Doc()
      another_document.database.should == MongoMapper.database
    end
    
    should "default collection name to class name tableized" do
      class ::Item
        include MongoMapper::Document
      end
      
      Item.collection.should be_instance_of(Mongo::Collection)
      Item.collection.name.should == 'items'
    end
    
    should "default collection name of namespaced class to tableized with dot separation" do
      module ::BloggyPoo
        class Post
          include MongoMapper::Document
        end
      end

      BloggyPoo::Post.collection.should be_instance_of(Mongo::Collection)
      BloggyPoo::Post.collection.name.should == 'bloggy_poo.posts'
    end

    should "allow setting the collection name" do
      @document.set_collection_name('foobar')
      @document.collection.should be_instance_of(Mongo::Collection)
      @document.collection.name.should == 'foobar'
    end
  end # Document class
  
  context "Documents that inherit from other documents" do
    should "default collection name to inherited class" do
      Message.collection_name.should == 'messages'
      Enter.collection_name.should   == 'messages'
      Exit.collection_name.should    == 'messages'
      Chat.collection_name.should    == 'messages'
    end

    should "default associations to inherited class" do
      Message.associations.keys.should include("room")
      Enter.associations.keys.should   include("room")
      Exit.associations.keys.should    include("room")
      Chat.associations.keys.should    include("room")
    end
  end
  
  context "descendants" do
    should "default to nil" do
      Enter.descendants.should be_nil
    end

    should "be recorded" do
      Message.descendants.should == [Enter, Exit, Chat]
    end
  end

  context "An instance of a document" do
    setup do
      @document = Doc do
        key :name, String
        key :age, Integer
      end
    end
    
    should "create id during initialization" do
      @document.new._id.should be_instance_of(Mongo::ObjectID)
    end
    
    should "have to_param that is string representation of id" do
      doc = @document.new(:id => Mongo::ObjectID.new)
      doc.to_param.should == doc.id.to_s
      doc.to_param.should be_instance_of(String)
    end
    
    should "have access to logger" do
      doc = @document.new
      doc.logger.should == @document.logger
      doc.logger.should be_instance_of(Logger)
    end

    should "have access to the class's collection" do
      doc = @document.new
      doc.collection.name.should == @document.collection.name
    end

    should "use default values if defined for keys" do
      @document.key :active, Boolean, :default => true

      @document.new.active.should be_true
      @document.new(:active => false).active.should be_false
    end
    
    should "use default values if defined even when custom data type" do
      @document.key :window, WindowSize, :default => WindowSize.new(600, 480)
      
      doc = @document.new
      doc.window.should == WindowSize.new(600, 480)
    end

    context "root document" do
      should "set self to the root document on embedded documents" do        
        klass = Doc()
        pets = EDoc()
        
        klass.many :pets, :class => pets
        
        doc = klass.new(:pets => [{}])
        doc.pets.first._root_document.should == doc        
      end
    end

    context "new?" do
      should "be true if no id" do
        @document.new.new?.should be_true
      end
      
      should "be true if id but using custom id and not saved yet" do
        @document.key :_id, String
        doc = @document.new
        doc.id = '1234'
        doc.new?.should be_true
      end
    end

    context "clone" do
      should "be new" do
        doc = @document.create(:name => "foo", :age => 27)
        clone = doc.clone
        clone.should be_new
      end

      should "copy the attributes" do
        doc = @document.create(:name => "foo", :age => 27)
        clone = doc.clone
        clone.name.should == "foo"
        clone.age.should == 27
      end
    end

    should "call inspect on the document's attributes instead of to_s when inspecting the document" do
      doc = @document.new(:animals => %w(dog cat))
      doc.inspect.should include(%(animals: ["dog", "cat"]))
    end

    context "equality" do
      setup do
        @oid = Mongo::ObjectID.new
      end
      
      should "delegate hash to _id" do
        doc = @document.new
        doc.hash.should == doc._id.hash
      end
      
      should "delegate eql to ==" do
        doc = @document.new
        other = @document.new
        doc.eql?(other).should == (doc == other)
        doc.eql?(doc).should == (doc == doc)
      end
      
      should "know if same object as another" do
        doc = @document.new
        doc.should equal(doc)
        doc.should_not equal(@document.new)
      end
      
      should "allow set operations on array of documents" do
        @document.key :parent_id, ObjectId
        @document.belongs_to :parent, :class => @document
        
        parent = @document.create
        child = @document.create(:parent => parent)
        
        ([child.parent] & [parent]).should == [parent]
      end
      
      should "be equal if id and class are the same" do
        (@document.new('_id' => @oid) == @document.new('_id' => @oid)).should be(true)
      end

      should "not be equal if class same but id different" do
        (@document.new('_id' => @oid) == @document.new('_id' => Mongo::ObjectID.new)).should be(false)
      end

      should "not be equal if id same but class different" do
        another_document = Doc()
        (@document.new('_id' => @oid) == another_document.new('_id' => @oid)).should be(false)
      end
    end
  end # instance of a document
end # DocumentTest
