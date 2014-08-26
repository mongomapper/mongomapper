require 'spec_helper'


describe "Document" do
  context "The Document Class" do
    before do
      @document = Doc()
    end

    it "should return false for embeddable" do
      Doc().embeddable?.should be_falsey
    end

    it "should have logger method" do
      @document.logger.should == MongoMapper.logger
      @document.logger.should be_instance_of(Logger)
    end

    it "should use default database by default" do
      @document.database.should == MongoMapper.database
    end

    it "should have a connection" do
      @document.connection.should be_instance_of(Mongo::MongoClient)
    end

    it "should allow setting different connection without affecting the default" do
      conn = Mongo::MongoClient.new
      @document.connection conn
      @document.connection.should == conn
      @document.connection.should_not == MongoMapper.connection
    end

    it "should allow setting a different database without affecting the default" do
      @document.set_database_name 'test2'
      @document.database_name.should == 'test2'
      @document.database.name.should == 'test2'

      another_document = Doc()
      another_document.database.should == MongoMapper.database
    end

    it "should allow setting the collection name" do
      @document.set_collection_name('foobar')
      @document.collection.name.should == 'foobar'
    end

    context ".collection" do
      it "should default collection name to class name tableized" do
        class ::Item
          include MongoMapper::Document
        end.collection.name.should == 'items'
      end

      it "should default collection name of namespaced class to tableized with dot separation" do
        module ::BloggyPoo
          class Post
            include MongoMapper::Document
          end.collection.name.should == 'bloggy_poo.posts'
        end
      end

      it "should be an instance of a Mongo::Collection" do
        @document.collection.should be_instance_of(Mongo::Collection)
      end
    end
  end # Document class

  context "Documents that inherit from other documents" do
    it "should default collection name to inherited class" do
      Message.collection_name.should == 'messages'
      Enter.collection_name.should   == 'messages'
      Exit.collection_name.should    == 'messages'
      Chat.collection_name.should    == 'messages'
    end

    it "should default associations to inherited class" do
      Message.associations.keys.should include(:room)
      Enter.associations.keys.should   include(:room)
      Exit.associations.keys.should    include(:room)
      Chat.associations.keys.should    include(:room)
    end
  end

  context "descendants" do
    it "should default to an empty array" do
      Enter.descendants.should == []
    end

    it "should be recorded" do
      Message.descendants.should == [Enter, Exit, Chat]
    end
  end

  context "An instance of a document" do
    before do
      @document = Doc do
        key :name, String
        key :age, Integer
      end
    end

    it "should respond to cache_key" do
      @document.new.should respond_to(:cache_key)
    end

    it "should create id during initialization" do
      @document.new._id.should be_instance_of(BSON::ObjectId)
    end

    it "should have access to logger" do
      doc = @document.new
      doc.logger.should == @document.logger
      doc.logger.should be_instance_of(Logger)
    end

    it "should have access to the class's collection" do
      doc = @document.new
      doc.collection.name.should == @document.collection.name
    end

    it "should use default values if defined for keys" do
      @document.key :active, Boolean, :default => true

      @document.new.active.should be_truthy
      @document.new(:active => false).active.should be_falsey
    end

    it "should use default values if defined even when custom data type" do
      @document.key :window, WindowSize, :default => WindowSize.new(600, 480)

      doc = @document.new
      doc.window.should == WindowSize.new(600, 480)
    end

    context "root document" do
      it "should set self to the root document on embedded documents" do
        klass = Doc()
        pets = EDoc()

        klass.many :pets, :class => pets

        doc = klass.new(:pets => [{}])
        doc.pets.first._root_document.should == doc
      end
    end

    context "new?" do
      it "should be true if no id" do
        @document.new.new?.should be_truthy
      end

      it "should be true if id but using custom id and not saved yet" do
        @document.key :_id, String
        doc = silence_stderr { @document.new }
        doc.id = '1234'
        doc.new?.should be_truthy
      end
    end

    context "equality" do
      before do
        @oid = BSON::ObjectId.new
      end

      it "should delegate hash to _id" do
        doc = @document.new
        doc.hash.should == doc._id.hash
      end

      it "should delegate eql to ==" do
        doc = @document.new
        other = @document.new
        doc.eql?(other).should == (doc == other)
        doc.eql?(doc).should == (doc == doc)
      end

      it "should know if same object as another" do
        doc = @document.new
        doc.should equal(doc)
        doc.should_not equal(@document.new)
      end

      it "should allow set operations on array of documents" do
        @document.key :parent_id, ObjectId
        @document.belongs_to :parent, :class => @document

        parent = @document.create
        child = @document.create(:parent => parent)

        ([child.parent] & [parent]).should == [parent]
      end

      it "should be equal if id and class are the same" do
        (@document.new('_id' => @oid) == @document.new('_id' => @oid)).should be(true)
      end

      it "should not be equal if class same but id different" do
        (@document.new('_id' => @oid) == @document.new('_id' => BSON::ObjectId.new)).should be(false)
      end

      it "should not be equal if id same but class different" do
        another_document = Doc()
        (@document.new('_id' => @oid) == another_document.new('_id' => @oid)).should be(false)
      end
    end

    context "nil attributes" do

      it "should list all the keys and default non nil attributes" do
       doc = @document.new
       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id']
      end

      it "should list all the keys and non nil attributes" do
       doc = @document.new(:name => "John")
       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id','name']
      end

      it "should list all the keys and pickup changed nil attributes" do
       doc = @document.new(:name => "John")
       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id','name']

       doc.name = nil

       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id']
      end

      it "should list all the keys and pickup changed nil and non-nil attributes" do
       doc = @document.new(:name => "John")
       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id','name']

       doc.name = nil
       doc.age = 12

       doc.keys.keys.sort.should == ['_id', 'age', 'name']
       doc.attributes.keys.sort.should == ['_id','age']
      end

    end

  end # instance of a document
end # DocumentTest

