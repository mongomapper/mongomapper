require 'spec_helper'

describe MongoMapper::Plugins::Serialization do

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
    TopLevelContact.include_root_in_json = true
    convert_to_json(@top_level_contact).should =~ %r{^\{"top_level_contact":\s?\{}
  end

  it "should include demodulized root" do
    Contact.include_root_in_json = true
    convert_to_json(@contact).should =~ %r{^\{"contact":\s?\{}
  end

  it "should encode all encodable attributes" do
    json = convert_to_json(@contact)

    json.should_not =~ %r{"_id"}
    json.should =~ %r{"name":"Konata Izumi"}
    json.should =~ %r{"age":16}
    json.should include(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    json.should =~ %r{"awesome":true}
    json.should =~ %r{"preferences":\{"shows":"anime"\}}
  end

  it "should allow attribute filtering with only" do
    json = convert_to_json(@contact, :only => [:name, :age])

    json.should_not =~ %r{"_id"}
    json.should =~ %r{"name":"Konata Izumi"}
    json.should =~ %r{"age":16}
    json.should_not =~ %r{"awesome"}
    json.should_not =~ %r{"created_at"}
    json.should_not =~ %r{"preferences"}
  end

  it "should allow attribute filtering with except" do
    json = convert_to_json(@contact, :except => [:name, :age])

    json.should_not =~ %r{"_id"}
    json.should_not =~ %r{"name"}
    json.should_not =~ %r{"age"}
    json.should =~ %r{"awesome"}
    json.should =~ %r{"created_at"}
    json.should =~ %r{"preferences"}
  end

  context "_id key" do
    it "should not be included by default" do
      json = convert_to_json(@contact)
      json.should_not =~ %r{"_id":}
    end

    it "should not be included even if :except is used" do
      json = convert_to_json(@contact, :except => :name)
      json.should_not =~ %r{"_id":}
    end
  end

  context "id method" do
    before do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    it "should be included by default" do
      json = convert_to_json(@contact)
      json.should =~ %r{"id"}
    end

    it "should be included when single method included" do
      json = convert_to_json(@contact, :methods => :label)
      json.should =~ %r{"id"}
      json.should =~ %r{"label":"Has cheezburger"}
      json.should =~ %r{"name":"Konata Izumi"}
      json.should_not =~ %r{"favorite_quote":"Constraints are liberating"}
    end

    it "should be included when multiple methods included" do
      json = convert_to_json(@contact, :methods => [:label, :favorite_quote])
      json.should =~ %r{"id"}
      json.should =~ %r{"label":"Has cheezburger"}
      json.should =~ %r{"favorite_quote":"Constraints are liberating"}
      json.should =~ %r{"name":"Konata Izumi"}
    end

    it "should not be included if :only is present" do
      json = convert_to_json(@contact, :only => :name)
      json.should_not =~ %r{"id":}
    end

    it "should be represented by a string" do
      json = convert_to_json(@contact)
      json.should =~ %r{"id":"}
    end
  end

  context "including methods" do
    before do
      def @contact.label; "Has cheezburger"; end
      def @contact.favorite_quote; "Constraints are liberating"; end
    end

    it "should include single method" do
      json = convert_to_json(@contact, :methods => :label)
      json.should =~ %r{"label":"Has cheezburger"}
    end

    it "should include multiple methods" do
      json = convert_to_json(@contact, :only => :name, :methods => [:label, :favorite_quote])
      json.should =~ %r{"label":"Has cheezburger"}
      json.should =~ %r{"favorite_quote":"Constraints are liberating"}
      json.should =~ %r{"name":"Konata Izumi"}
      json.should_not =~ %r{"age":16}
      json.should_not =~ %r{"awesome"}
      json.should_not =~ %r{"created_at"}
      json.should_not =~ %r{"preferences"}
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
      json =convert_to_json(@contacts, :only => :name)
      json.should =~ %r{\{"name":"David"\}}
      json.should =~ %r{\{"name":"Mary"\}}
    end

    it "should allow attribute filtering with except" do
      json = convert_to_json(@contacts, :except => [:name, :preferences, :awesome, :created_at, :updated_at])
      json.should =~ %r{"age":39}
      json.should =~ %r{"age":14}
      json.should_not =~ %r{"name":}
      json.should_not =~ %r{"preferences":}
      json.should_not =~ %r{"awesome":}
      json.should_not =~ %r{"created_at":}
      json.should_not =~ %r{"updated_at":}
    end
  end

  it "should allow options for hash of records" do
    contacts = {
      1 => Contact.new(:name => 'David', :age => 39),
      2 => Contact.new(:name => 'Mary', :age => 14)
    }
    json = convert_to_json(contacts, :only => [1, :name])
    json.should =~ %r{"1":}
    json.should =~ %r{\{"name":"David"\}}
    json.should_not =~ %r{"2":}
  end

  it "should include embedded attributes" do
    contact = Contact.new(:name => 'John', :age => 27)
    contact.tags = [Tag.new(:name => 'awesome'), Tag.new(:name => 'ruby')]
    json = convert_to_json(contact)
    json.should =~ %r{"tags":}
    json.should =~ %r{"name":"awesome"}
    json.should =~ %r{"name":"ruby"}
  end

  it "should include dynamic attributes" do
    contact = Contact.new(:name => 'John', :age => 27, :foo => 'bar')
    contact['smell'] = 'stinky'
    json = convert_to_json(contact)
    json.should =~ %r{"smell":"stinky"}
  end
end
