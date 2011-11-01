require 'test_helper'

class XmlSerializationTest < Test::Unit::TestCase
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

    many :tags, :class_name => 'XmlSerializationTest::Tag'
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
    assert_match %r{<top-level-contact>}, @top_level_contact.to_xml
  end

  should "include demodulized root" do
    assert_match %r{<contact>}, @contact.to_xml
  end

  should "encode all encodable attributes" do
    xml = @contact.to_xml

    assert_no_match %r{_id}, xml
    assert_match %r{<id>#{@contact.id}</id>}, xml
    assert_match %r{<name>Konata Izumi</name>}, xml
    assert_match %r{<age.*>16</age>}, xml
    assert_match %r(<created-at type="datetime">), xml
    assert_match %r{<awesome type="boolean">true</awesome>}, xml
    assert_match %r{<preferences>}, xml
    assert_match %r{<shows>anime</shows>}, xml
  end

  should "allow attribute filtering with only" do
    xml = @contact.to_xml(:only => [:name, :age])

    assert_no_match %r{<id>}, xml
    assert_match %r{<name>Konata Izumi</name>}, xml
    assert_match %r{<age type="integer">16</age>}, xml
    assert_no_match %r{awesome}, xml
    assert_no_match %r{created-at}, xml
    assert_no_match %r{preferences}, xml
  end

  should "allow attribute filtering with except" do
    xml = @contact.to_xml(:except => [:name, :age])

    assert_no_match %r{<name>Konata Izumi</name>}, xml
    assert_no_match %r{<age type="integer">16</age>}, xml
    assert_match %r{<id>}, xml
    assert_match %r{awesome}, xml
    assert_match %r{created-at}, xml
    assert_match %r{preferences}, xml
  end

  context "_id key" do
    should "not be included by default" do
      assert_no_match %r{_id}, @contact.to_xml
    end

    should "not be included even if :except is used" do
      assert_no_match %r{_id}, @contact.to_xml(:except => :name)
    end
  end

  context "id method" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    should "be included by default" do
      assert_match %r{<id>#{@contact.id}</id>}, @contact.to_xml
    end

    should "be included when single method included" do
      xml = @contact.to_xml(:methods => :label)
      assert_match %r{<id>}, xml
      assert_match %r{<label>Has cheezburger</label>}, xml
      assert_match %r{<name>Konata Izumi</name>}, xml
      assert_no_match %r{favorite_quote}, xml
    end

    should "be included when multiple methods included" do
      xml = @contact.to_xml(:methods => [:label, :favorite_quote])
      assert_match %r{<id>}, xml
      assert_match %r{<label>Has cheezburger</label>}, xml
      assert_match %r{<name>Konata Izumi</name>}, xml
      assert_match %r{<favorite-quote>Constraints are liberating</favorite-quote>}, xml
    end

    should "not be included if :only is present" do
      assert_no_match %r{<id}, @contact.to_xml(:only => :name)
    end

    should "be represented by a string" do
      assert_match %r{<id>}, @contact.to_xml
    end
  end

  context "including methods" do
    setup do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    should "include single method" do
      assert_match %r{<label>Has cheezburger</label>}, @contact.to_xml(:methods => :label)
    end

    should "include multiple methods" do
      xml = @contact.to_xml(:only => :name, :methods => [:label, :favorite_quote])
      assert_match %r{<label>Has cheezburger</label>}, xml
      assert_match %r{<favorite-quote>Constraints are liberating</favorite-quote>}, xml
      assert_match %r{<name>Konata Izumi</name>}, xml
      assert_no_match %r{age}, xml
      assert_no_match %r{awesome}, xml
      assert_no_match %r{created-at}, xml
      assert_no_match %r{preferences}, xml

      # Assert only one tag is created
      xml.scan(/favorite-quote/).size.should == 2
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
      xml = @contacts.to_xml(:only => :name)
      assert_match %r{<name>David</name>}, xml
      assert_match %r{<name>Mary</name>},  xml
    end

    should "allow attribute filtering with except" do
      xml = @contacts.to_xml(:except => [:name, :preferences, :awesome, :created_at, :updated_at])
      assert_match %r{<age type="integer">39</age>}, xml
      assert_match %r{<age type="integer">14</age>}, xml
      assert_no_match %r{name},        xml
      assert_no_match %r{preferences}, xml
      assert_no_match %r{awesome},     xml
      assert_no_match %r{created-at},  xml
      assert_no_match %r{updated-at},  xml
    end
  end

  should "include embedded attributes" do
    contact = Contact.new(:name => 'John', :age => 27)
    contact.tags = [Tag.new(:name => 'awesome'), Tag.new(:name => 'ruby')]
    xml = contact.to_xml
    assert_match %r{<tags type="array">}, xml
    assert_match %r{<id>#{contact.tags[0].id}</id>}, xml
    assert_match %r{<id>#{contact.tags[1].id}</id>}, xml
    assert_match %r{<name>awesome</name>}, xml
    assert_match %r{<name>ruby</name>}, xml
  end

  should "include dynamic attributes" do
    contact = Contact.new(:name => 'John', :age => 27, :foo => 'bar')
    contact['smell'] = 'stinky'
    assert_match %r{<smell>stinky</smell>}, contact.to_xml
  end
end
