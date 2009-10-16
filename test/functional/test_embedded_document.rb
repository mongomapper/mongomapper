require 'test_helper'
require 'models'

class EmbeddedDocumentTest < Test::Unit::TestCase
  def setup
    @document = Class.new do
      include MongoMapper::Document
      set_collection_name 'users'

      key :first_name, String
      key :last_name, String
    end
    @document.collection.clear
  end
    
  context "Saving a document with an embedded document" do
    setup do
      @document.class_eval do
        key :foo, Address
      end
      
      @address = Address.new(:city => 'South Bend', :state => 'IN')
      @doc = @document.new(:foo => @address)
    end
    
    should "embed embedded document" do
      @doc.save
      @doc.foo.city.should == 'South Bend'
      @doc.foo.state.should == 'IN'

      from_db = @document.find(@doc.id)
      from_db.foo.city.should == 'South Bend'
      from_db.foo.state.should == 'IN'
    end
  end
  
  context "new?" do
    setup do
      @document.class_eval do
        key :foo, Address
      end
    end

    should "be new until document is saved" do
      address = Address.new(:city => 'South Bend', :state => 'IN')
      doc = @document.new(:foo => address)
      address.new?.should == true
    end
    
    should "not be new after document is saved" do
      address = Address.new(:city => 'South Bend', :state => 'IN')
      doc = @document.new(:foo => address)
      doc.save
      doc.foo.new?.should == false
    end
    
    should "not be new when document is read back" do
      address = Address.new(:city => 'South Bend', :state => 'IN')
      doc = @document.new(:foo => address)
      doc.save
      read_doc = @document.find(doc.id)
      read_doc.foo.new?.should == false
    end
  end
  
  context "save" do
    should "save the root document" do
      person = RealPerson.create

      pet = Pet.new :name => 'sparky'
      person.pets << pet
      pet.save

      doc = RealPerson.find(person.id)
      doc.pets.first.should == pet
    end
    
    should "save new keys" do
      person = RealPerson.new
      person[:new_attribute] = 'foobar'
      person.save
      from_db = RealPerson.find(person.id)
      person.new_attribute.should == 'foobar'
    end
  end
  
  context "update_attributes" do
    should "save the root document" do
      person = RealPerson.create

      pet = Pet.new(:name => 'sparky')
      person.pets << pet
      pet.save

      doc = RealPerson.find(person.id)
      pet = doc.pets.first
      pet.update_attributes :name => 'koda'

      doc = RealPerson.find(person.id)
      embedded = doc.pets.first
      embedded.id.should == pet.id
      embedded.name.should == 'koda'
    end
  end  
end
