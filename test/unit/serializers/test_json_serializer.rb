require 'test_helper'

class JsonSerializationTest < Test::Unit::TestCase
  class Tag
    include MongoMapper::EmbeddedDocument
    key :name, String
  end
  
  class Contact
    include MongoMapper::Document
    key :name, String
    key :age, Integer
    key :created_at, Time
    key :awesome, Boolean
    key :preferences, Hash
    
    many :tags, :class_name => 'JsonSerializationTest::Tag'
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

    assert_no_match %r{"_id"}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end
  
  should "allow attribute filtering with only" do
    json = @contact.to_json(:only => [:name, :age])

    assert_no_match %r{"_id"}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert_no_match %r{"awesome"}, json
    assert_no_match %r{"created_at"}, json
    assert_no_match %r{"preferences"}, json
  end
  
  should "allow attribute filtering with except" do
    json = @contact.to_json(:except => [:name, :age])

    assert_no_match %r{"_id"}, json
    assert_no_match %r{"name"}, json
    assert_no_match %r{"age"}, json
    assert_match %r{"awesome"}, json
    assert_match %r{"created_at"}, json
    assert_match %r{"preferences"}, json
  end
  
  context "_id key" do
    should "not be included by default" do
      json = @contact.to_json
      assert_no_match %r{"_id":}, json
    end
    
    should "not be included even if :except is used" do
      json = @contact.to_json(:except => :name)
      assert_no_match %r{"_id":}, json
    end
  end
  
  context "id method" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end
    
    should "be included by default" do
      json = @contact.to_json
      assert_match %r{"id"}, json
    end
    
    should "be included when single method included" do
      json = @contact.to_json(:methods => :label)
      assert_match %r{"id"}, json
      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"name":"Konata Izumi"}, json
      assert_no_match %r{"favorite_quote":"Constraints are liberating"}, json
    end
    
    should "be included when multiple methods included" do
      json = @contact.to_json(:methods => [:label, :favorite_quote])
      assert_match %r{"id"}, json
      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"favorite_quote":"Constraints are liberating"}, json
      assert_match %r{"name":"Konata Izumi"}, json
    end
    
    should "not be included if :only is present" do
      json = @contact.to_json(:only => :name)
      assert_no_match %r{"id":}, json
    end
  end  
  
  context "including methods" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end
    
    should "include single method" do
      json = @contact.to_json(:methods => :label)
      assert_match %r{"label":"Has cheezburger"}, json
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
      json = @contacts.to_json(:only => :name)
      assert_match %r{\{"name":"David"\}}, json
      assert_match %r{\{"name":"Mary"\}}, json
    end
    
    should "allow attribute filtering with except" do
      json = @contacts.to_json(:except => [:name, :preferences, :awesome, :created_at, :updated_at])
      assert_match %r{"age":39},          json
      assert_match %r{"age":14},          json
      assert_no_match %r{"name":},        json
      assert_no_match %r{"preferences":}, json
      assert_no_match %r{"awesome":},     json
      assert_no_match %r{"created_at":},  json
      assert_no_match %r{"updated_at":},  json
    end
  end
  
  should "allow options for hash of records" do
    contacts = {
      1 => Contact.new(:name => 'David', :age => 39),
      2 => Contact.new(:name => 'Mary', :age => 14)
    }
    json = contacts.to_json(:only => [1, :name])
    assert_match %r{"1":},               json
    assert_match %r{\{"name":"David"\}}, json
    assert_no_match %r{"2":},            json
  end
  
  should "include embedded attributes" do
    contact = Contact.new(:name => 'John', :age => 27)
    contact.tags = [Tag.new(:name => 'awesome'), Tag.new(:name => 'ruby')]
    json = contact.to_json
    assert_match %r{"tags":}, json
    assert_match %r{"name":"awesome"}, json
    assert_match %r{"name":"ruby"}, json
  end
  
  should "include dynamic attributes" do
    contact = Contact.new(:name => 'John', :age => 27, :foo => 'bar')
    contact['smell'] = 'stinky'
    json = contact.to_json
    assert_match %r{"smell":"stinky"}, json
  end
end
