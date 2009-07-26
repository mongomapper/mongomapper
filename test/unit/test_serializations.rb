require 'test_helper'

class SerializationTest < Test::Unit::TestCase
  def setup
    @document = Class.new do
      include MongoMapper::EmbeddedDocument
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
  
  [:json].each do |format|
    context format do
      should "be reversable" do
        serialized = @instance.send("to_#{format}")
        unserialized = @document.new.send("from_#{format}", serialized)

        assert_equal @instance, unserialized
      end
      
      should "allow attribute only filtering" do
        serialized = @instance.send("to_#{format}", :only => [ :age, :name ])
        unserialized = @document.new.send("from_#{format}", serialized)

        assert_equal @instance.name, unserialized.name
        assert_equal @instance.age, unserialized.age
        assert_nil unserialized.awesome
        assert_nil unserialized.created_at
      end
      
      should "allow attribute except filtering" do
        serialized = @instance.send("to_#{format}", :except => [ :age, :name ])
        unserialized = @document.new.send("from_#{format}", serialized)
        
        assert_nil unserialized.name
        assert_nil unserialized.age
        assert_equal @instance.awesome, unserialized.awesome
      end
    end
  end
end
