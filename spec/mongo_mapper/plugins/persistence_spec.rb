require 'spec_helper'

describe MongoMapper::Plugins::Persistence do
  it "should use default database by default" do
    document.database.should == MongoMapper.database
  end

  it "should have a connection" do
    document.connection.should be_instance_of(Mongo::Connection)
  end

  it "should allow setting different connection without affecting the default" do
    conn = Mongo::Connection.new
    document.connection conn
    document.connection.should == conn
    document.connection.should_not == MongoMapper.connection
  end

  it "should allow setting a different database without affecting the default" do
    document.set_database_name 'test2'
    document.database_name.should == 'test2'
    document.database.name.should == 'test2'

    Doc().database.should == MongoMapper.database
  end

  it "should allow setting the collection name" do
    document.set_collection_name('foobar')
    document.collection.name.should == 'foobar'
  end

  it "should have logger method" do
    document.logger.should == MongoMapper.logger
    document.logger.should be_instance_of(Logger)
  end

  describe ".collection" do
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
      document.collection.should be_instance_of(Mongo::Collection)
    end

    it "should default collection name to inherited class" do
      Message.collection_name.should == 'messages'
      Enter.collection_name.should   == 'messages'
      Exit.collection_name.should    == 'messages'
      Chat.collection_name.should    == 'messages'
    end
  end

  describe 'an instance' do
    it "should have access to the class's collection" do
      document.new.collection.name.should == document.collection.name
    end
  end
end
