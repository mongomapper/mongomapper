require 'spec_helper'

describe MongoMapper::Plugins::Serialization do
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

    many :tags
  end

  before do
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

  after do
    Kernel.send(:remove_const, 'TopLevelContact') if Object.const_defined?('TopLevelContact')
  end

  it "should include root for class with no module" do
    @top_level_contact.to_xml.should =~ %r{<top-level-contact>}
  end

  it "should include demodulized root" do
    @contact.to_xml.should =~ %r{<contact>}
  end

  it "should encode all encodable attributes" do
    xml = @contact.to_xml

    xml.should_not =~ %r{_id}
    xml.should =~ %r{<id>#{@contact.id}</id>}
    xml.should =~ %r{<name>Konata Izumi</name>}
    xml.should =~ %r{<age.*>16</age>}
    xml.should =~ %r(<created-at type="datetime">)
    xml.should =~ %r{<awesome type="boolean">true</awesome>}
    xml.should =~ %r{<preferences>}
    xml.should =~ %r{<shows>anime</shows>}
  end

  it "should allow attribute filtering with only" do
    xml = @contact.to_xml(:only => [:name, :age])

    xml.should_not =~ %r{<id>}
    xml.should =~ %r{<name>Konata Izumi</name>}
    xml.should =~ %r{<age type="integer">16</age>}
    xml.should_not =~ %r{awesome}
    xml.should_not =~ %r{created-at}
    xml.should_not =~ %r{preferences}
  end

  it "should allow attribute filtering with except" do
    xml = @contact.to_xml(:except => [:name, :age])

    xml.should_not =~ %r{<name>Konata Izumi</name>}
    xml.should_not =~ %r{<age type="integer">16</age>}
    xml.should =~ %r{<id>}
    xml.should =~ %r{awesome}
    xml.should =~ %r{created-at}
    xml.should =~ %r{preferences}
  end

  context "_id key" do
    it "should not be included by default" do
      @contact.to_xml.should_not =~ %r{_id}
    end

    it "should not be included even if :except is used" do
      @contact.to_xml(:except => :name).should_not =~ %r{_id}
    end
  end

  context "id method" do
    before do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    it "should be included by default" do
      @contact.to_xml.should =~ %r{<id>#{@contact.id}</id>}
    end

    it "should be included when single method included" do
      xml = @contact.to_xml(:methods => :label)
      xml.should =~ %r{<id>}
      xml.should =~ %r{<label>Has cheezburger</label>}
      xml.should =~ %r{<name>Konata Izumi</name>}
      xml.should_not =~ %r{favorite_quote}
    end

    it "should be included when multiple methods included" do
      xml = @contact.to_xml(:methods => [:label, :favorite_quote])
      xml.should =~ %r{<id>}
      xml.should =~ %r{<label>Has cheezburger</label>}
      xml.should =~ %r{<name>Konata Izumi</name>}
      xml.should =~ %r{<favorite-quote>Constraints are liberating</favorite-quote>}
    end

    it "should not be included if :only is present" do
      @contact.to_xml(:only => :name).should_not =~ %r{<id}
    end

    it "should be represented by a string" do
      @contact.to_xml.should =~ %r{<id>}
    end
  end

  context "including methods" do
    before do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    it "should include single method" do
      @contact.to_xml(:methods => :label).should =~ %r{<label>Has cheezburger</label>}
    end

    it "should include multiple methods" do
      xml = @contact.to_xml(:only => :name, :methods => [:label, :favorite_quote])
      xml.should =~ %r{<label>Has cheezburger</label>}
      xml.should =~ %r{<favorite-quote>Constraints are liberating</favorite-quote>}
      xml.should =~ %r{<name>Konata Izumi</name>}
      xml.should_not =~ %r{age}
      xml.should_not =~ %r{awesome}
      xml.should_not =~ %r{created-at}
      xml.should_not =~ %r{preferences}

      # Assert only one tag is created
      xml.scan(/favorite-quote/).size.should == 2
    end
  end

  context "array of records" do
    before do
      @contacts = [
        Contact.new(:name => 'David', :age => 39),
        Contact.new(:name => 'Mary', :age => 14)
      ]
    end

    it "should allow attribute filtering with only" do
      xml = @contacts.to_xml(:only => :name)
      xml.should =~ %r{<name>David</name>}
      xml.should =~ %r{<name>Mary</name>}
    end

    it "should allow attribute filtering with except" do
      xml = @contacts.to_xml(:except => [:name, :preferences, :awesome, :created_at, :updated_at])
      xml.should =~ %r{<age type="integer">39</age>}
      xml.should =~ %r{<age type="integer">14</age>}
      xml.should_not =~ %r{name}
      xml.should_not =~ %r{preferences}
      xml.should_not =~ %r{awesome}
      xml.should_not =~ %r{created-at}
      xml.should_not =~ %r{updated-at}
    end
  end

  it "should include embedded attributes" do
    contact = Contact.new(:name => 'John', :age => 27)
    contact.tags = [Tag.new(:name => 'awesome'), Tag.new(:name => 'ruby')]
    xml = contact.to_xml
    xml.should =~ %r{<tags type="array">}
    xml.should =~ %r{<id>#{contact.tags[0].id}</id>}
    xml.should =~ %r{<id>#{contact.tags[1].id}</id>}
    xml.should =~ %r{<name>awesome</name>}
    xml.should =~ %r{<name>ruby</name>}
  end

  it "should include dynamic attributes" do
    contact = Contact.new(:name => 'John', :age => 27, :foo => 'bar')
    contact['smell'] = 'stinky'
    contact.to_xml.should =~ %r{<smell>stinky</smell>}
  end
end
