require 'test_helper'

class SerializationTest < Test::Unit::TestCase
  def setup
    @document = EDoc do
      key :name, String
      key :age, Integer
      key :awesome, Boolean
      key :preferences, Hash
      key :created_at, Time
    end

    @instance = @document.new(
      :name        => 'John Doe',
      :age         => 25,
      :awesome     => true,
      :preferences => {:language => 'Ruby'},
      :created_at  => Time.now.change(:usec => 0)
    )
  end

  context "#serializable_hash" do
    class List
      include MongoMapper::Document
      key :name
      many :items,          :class_name => 'SerializationTest::Item'
      belongs_to :creator,  :class_name => 'SerializationTest::User'
    end

    class Item
      include MongoMapper::Document

      key :title
      key :description
      many :assignments, :class_name => 'SerializationTest::Assignment'

      def a_method
        1
      end
    end

    class Assignment
      include MongoMapper::EmbeddedDocument
      belongs_to :assigned_by,  :class_name => 'SerializationTest::User'
      belongs_to :user,         :class_name => 'SerializationTest::User'

      def serializable_hash(options = {})
        super({:only => :user_id}.merge(options))
      end
    end

    class User
      include MongoMapper::Document
      key :name, String
    end

    setup do
      @user1 = User.new(:name => 'Brandon')
      @user2 = User.new(:name => 'John')
      @item = Item.new(
        :title => 'Serialization',
        :description => 'Make it work like magic!',
        :assignments => [
          Assignment.new(:assigned_by => @user1, :user => @user2)
        ]
      )
    end

    should "only include specified attributes with :only option" do
      @item.serializable_hash(:only => :title).should == {'title' => 'Serialization'}
    end

    should "exclude attributes specified with :except option" do
      hash = @item.serializable_hash(:except => :description)
      hash['title'].should_not be_nil
      hash['description'].should be_nil
    end

    should "add :methods with :only option" do
      @item.serializable_hash(:only => :title, :methods => :a_method).should == {
        'title' => 'Serialization',
        'a_method' => 1
      }
    end

    should "call #serializable_hash on embedded many docs" do
      @item.serializable_hash.should == {
        'id'          => @item.id,
        'title'       => 'Serialization',
        'description' => 'Make it work like magic!',
        'assignments' => [{'user_id' => @user2.id}]
      }
    end

    context "with :include" do
      setup do
        @list = List.new(:title => 'MongoMapper', :items => [@item], :creator => @user1)
      end

      should "add many association" do
        hash = @list.serializable_hash(:include => :items)
        hash['items'].should be_instance_of(Array)
        hash['items'].first['title'].should == 'Serialization'
      end

      should "add belongs_to association" do
        hash = @list.serializable_hash(:include => :creator)
        hash['creator'].should == @user1.serializable_hash
      end

      should "add one association" do
        author_class = Doc do
          key :post_id, ObjectId
        end
        post_class = Doc('Post') do
          one :author, :class => author_class
        end

        author = author_class.new
        hash = post_class.new(:author => author).serializable_hash(:include => :author)
        hash['author'].should == author.serializable_hash
      end

      should "include multiple associations" do
        hash = @list.serializable_hash(:include => [:items, :creator])
        hash['items'].should be_instance_of(Array)
        hash['creator'].should == @user1.serializable_hash
      end

      should "include multiple associations with options" do
        hash = @list.serializable_hash(:include => {:creator => {:only => :name}})
        hash['creator'].should == @user1.serializable_hash(:only => :name)
      end
    end
  end

  [:json, :xml].each do |format|
    context format do
      should "be reversable" do
        serialized = @instance.send("to_#{format}")
        unserialized = @document.send("from_#{format}", serialized)

        assert_equal @instance, unserialized
      end

      should "allow attribute only filtering" do
        serialized = @instance.send("to_#{format}", :only => [ :age, :name ])
        unserialized = @document.send("from_#{format}", serialized)

        assert_equal @instance.name, unserialized.name
        assert_equal @instance.age, unserialized.age
        assert ! unserialized.awesome
        assert_nil unserialized.created_at
      end

      should "allow attribute except filtering" do
        serialized = @instance.send("to_#{format}", :except => [ :age, :name ])
        unserialized = @document.send("from_#{format}", serialized)

        assert_nil unserialized.name
        assert_nil unserialized.age
        assert_equal @instance.awesome, unserialized.awesome
      end
    end
  end
end
