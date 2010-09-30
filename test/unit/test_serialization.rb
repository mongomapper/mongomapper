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
      many :items, :class_name => 'SerializationTest::Item'
    end

    class Item
      include MongoMapper::EmbeddedDocument

      key :title
      key :description

      def serializable_hash(options = {})
        super({:only => :title}.merge(options))
      end
    end

    setup do
      @list = List.new(:name => 'Awesome Things', :items => [
        Item.new(:title => 'MongoMapper', :description => 'The best ODM evar!')
      ])
    end

    should "call #serializable_hash on embedded many docs" do
      @list.serializable_hash.should == {
        'id'    => @list.id,
        'name'  => 'Awesome Things',
        'items' => [{'title' => 'MongoMapper'}]
      }
    end

    should "call #serializable_hash on single embedded doc" do
      @list.serializable_hash.should == {
        'id'    => @list.id,
        'name'  => 'Awesome Things',
        'items' => [{'title' => 'MongoMapper'}]
      }
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
