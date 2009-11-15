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
    @document.collection.remove
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

      doc = @doc.reload
      doc.foo.city.should == 'South Bend'
      doc.foo.state.should == 'IN'
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
      
      doc = doc.reload
      doc.foo.new?.should == false
    end
  end
  
  context "save" do
    should "save the root document" do
      person = RealPerson.create

      pet = Pet.new :name => 'sparky'
      person.pets << pet
      pet.save

      person = person.reload
      person.pets.first.should == pet
    end
    
    should "save new keys" do
      person = RealPerson.new
      person[:new_attribute] = 'foobar'
      person.save
      
      person = person.reload
      person.new_attribute.should == 'foobar'
    end
  end
  
  context "update_attributes" do
    should "save the root document" do
      person = RealPerson.create

      pet = Pet.new(:name => 'sparky')
      person.pets << pet
      pet.save

      person = person.reload
      pet = person.pets.first
      pet.update_attributes :name => 'koda'

      person = person.reload
      person.pets.first._id.should == pet._id
      person.pets.first.name.should == 'koda'
    end
  end  
end
