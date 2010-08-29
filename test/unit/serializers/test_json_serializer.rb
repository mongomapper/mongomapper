require 'test_helper'
require 'active_support/version'

class JsonSerializationTest < Test::Unit::TestCase

  # Helper function in case things change in the future
  # - replacing all those to_json calls was a nightmare
  def convert_to_json(object, options={})
    ActiveSupport::JSON.encode(object, options)
  end

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
    Kernel.const_set('TopLevelContact', Doc('TopLevelContact'))
    TopLevelContact.key :name, String

    Contact.include_root_in_json = false
    @contact = Contact.new(
      :name        => 'Konata Izumi',
      :age         => 16,
      :created_at  => Time.utc(2006, 8, 1),
      :awesome     => true,
      :preferences => { :shows => 'anime' }
    )
    @top_level_contact = TopLevelContact.new(
      :name        => 'Konata Izumi'
    )
  end

  def teardown
    Kernel.send(:remove_const, 'TopLevelContact') if Object.const_defined?('TopLevelContact')
  end

  should "include root for class with no module" do
    TopLevelContact.include_root_in_json = true
    assert_match %r{^\{"top_level_contact":\s?\{}, convert_to_json(@top_level_contact)
  end

  should "include demodulized root" do
    Contact.include_root_in_json = true
    assert_match %r{^\{"contact":\s?\{}, convert_to_json(@contact)
  end

  should "encode all encodable attributes" do
    json = convert_to_json(@contact)

    assert_no_match %r{"_id"}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  should "allow attribute filtering with only" do
    json = convert_to_json(@contact, :only => [:name, :age])

    assert_no_match %r{"_id"}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert_no_match %r{"awesome"}, json
    assert_no_match %r{"created_at"}, json
    assert_no_match %r{"preferences"}, json
  end

  should "allow attribute filtering with except" do
    json = convert_to_json(@contact, :except => [:name, :age])

    assert_no_match %r{"_id"}, json
    assert_no_match %r{"name"}, json
    assert_no_match %r{"age"}, json
    assert_match %r{"awesome"}, json
    assert_match %r{"created_at"}, json
    assert_match %r{"preferences"}, json
  end

  context "_id key" do
    should "not be included by default" do
      json = convert_to_json(@contact)
      assert_no_match %r{"_id":}, json
    end

    should "not be included even if :except is used" do
      json = convert_to_json(@contact, :except => :name)
      assert_no_match %r{"_id":}, json
    end
  end

  context "id method" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    should "be included by default" do
      json = convert_to_json(@contact)
      assert_match %r{"id"}, json
    end

    should "be included when single method included" do
      json = convert_to_json(@contact, :methods => :label)
      assert_match %r{"id"}, json
      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"name":"Konata Izumi"}, json
      assert_no_match %r{"favorite_quote":"Constraints are liberating"}, json
    end

    should "be included when multiple methods included" do
      json = convert_to_json(@contact, :methods => [:label, :favorite_quote])
      assert_match %r{"id"}, json
      assert_match %r{"label":"Has cheezburger"}, json
      assert_match %r{"favorite_quote":"Constraints are liberating"}, json
      assert_match %r{"name":"Konata Izumi"}, json
    end

    should "not be included if :only is present" do
      json = convert_to_json(@contact, :only => :name)
      assert_no_match %r{"id":}, json
    end

    should "be represented by a string" do
      json = convert_to_json(@contact)
      assert_match %r{"id":"}, json
    end
  end

  context "including methods" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    should "include single method" do
      json = convert_to_json(@contact, :methods => :label)
      assert_match %r{"label":"Has cheezburger"}, json
    end

    should "include multiple methods" do
      json = convert_to_json(@contact, :only => :name, :methods => [:label, :favorite_quote])
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
      json =convert_to_json(@contacts, :only => :name)
      assert_match %r{\{"name":"David"\}}, json
      assert_match %r{\{"name":"Mary"\}}, json
    end

    should "allow attribute filtering with except" do
      json = convert_to_json(@contacts, :except => [:name, :preferences, :awesome, :created_at, :updated_at])
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
    json = convert_to_json(contacts, :only => [1, :name])
    assert_match %r{"1":},               json
    assert_match %r{\{"name":"David"\}}, json
    assert_no_match %r{"2":},            json
  end

  should "include embedded attributes" do
    contact = Contact.new(:name => 'John', :age => 27)
    contact.tags = [Tag.new(:name => 'awesome'), Tag.new(:name => 'ruby')]
    json = convert_to_json(contact)
    assert_match %r{"tags":}, json
    assert_match %r{"name":"awesome"}, json
    assert_match %r{"name":"ruby"}, json
  end

  should "include dynamic attributes" do
    contact = Contact.new(:name => 'John', :age => 27, :foo => 'bar')
    contact['smell'] = 'stinky'
    json = convert_to_json(contact)
    assert_match %r{"smell":"stinky"}, json
  end
end
