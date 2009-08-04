require 'test_helper'

class JsonSerializationTest < Test::Unit::TestCase
  class Contact
    include MongoMapper::Document
    key :name, String
    key :age, Integer
    key :created_at, Time
    key :awesome, Boolean
    key :preferences, Hash
  end
  
  def setup
    Contact.include_root_in_json = false
    @contact = Contact.new(
      :name        => 'Konata Izumi',
      :age         => 16,
      :created_at  => Time.utc(2006, 8, 1),
      :awesome     => true,
      :preferences => { :shows => 'anime' }
    )
  end
  
  should "include demodulized root" do
    Contact.include_root_in_json = true
    assert_match %r{^\{"contact": \{}, @contact.to_json
  end
  
  should "encode all encodable attributes" do
    json = @contact.to_json

    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end
  
  should "allow attribute filtering with only" do
    json = @contact.to_json(:only => [:name, :age])

    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert_no_match %r{"awesome"}, json
    assert_no_match %r{"created_at"}, json
    assert_no_match %r{"preferences"}, json
  end
  
  should "allow attribute filtering with except" do
    json = @contact.to_json(:except => [:name, :age])

    assert_no_match %r{"name"}, json
    assert_no_match %r{"age"}, json
    assert_match %r{"awesome"}, json
    assert_match %r{"created_at"}, json
    assert_match %r{"preferences"}, json
  end
  
  context "including methods" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end
    
    should "include label method" do
      json = @contact.to_json(:methods => :label)
      assert_match %r{"label":"Has cheezburger"}, json
    end
    
    should "include name and label method" do
      json = @contact.to_json(:only => :name, :methods => :label)

      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"name":"Konata Izumi"}, json
      assert_no_match %r{"age":16}, json
      assert_no_match %r{"awesome"}, json
      assert_no_match %r{"created_at"}, json
      assert_no_match %r{"preferences"}, json
    end
    
    should "include multiple methods" do
      json = @contact.to_json(:only => :name, :methods => [:label, :favorite_quote])
      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"favorite_quote":"Constraints are liberating"}, json
      assert_match %r{"name":"Konata Izumi"}, json
      assert_no_match %r{"age":16}, json
      assert_no_match %r{"awesome"}, json
      assert_no_match %r{"created_at"}, json
      assert_no_match %r{"preferences"}, json
    end
  end
  
  context "array of records" do
    setup do
      @contacts = [
        Contact.new(:name => 'David', :age => 39),
        Contact.new(:name => 'Mary', :age => 14)
      ]
    end

    should "allow attribute filtering with only" do
      assert_equal %([{"name":"David"},{"name":"Mary"}]), @contacts.to_json(:only => :name)
    end
    
    should "allow attribute filtering with except" do
      json = @contacts.to_json(:except => [:name, :preferences, :awesome, :created_at, :updated_at, :_id])
      assert_equal %([{"id":"","age":39},{"id":"","age":14}]), json
    end
  end
  
  should "allow options for hash of records" do
    contacts = {
      1 => Contact.new(:name => 'David', :age => 39),
      2 => Contact.new(:name => 'Mary', :age => 14)
    }

    assert_equal %({"1":{"name":"David"}}), contacts.to_json(:only => [1, :name])
  end
  
end
