require 'test_helper'

class Address
  include MongoMapper::EmbeddedDocument
  
  key :address, String
  key :city,    String
  key :state,   String
  key :zip,     Integer
end


class AssociationsTest < Test::Unit::TestCase
  def setup
    @document = Class.new do
      include MongoMapper::Document
    end
  end
  
  context "Many embedded documents" do
    setup do
      @document.class_eval do
        many :addresses
      end
    end

    should "default reader to empty array" do
      instance = @document.new
      instance.addresses.should == []
    end
  
    should "allow adding to association like it was an array" do
      instance = @document.new
      instance.addresses << Address.new
      instance.addresses.push Address.new
      instance.addresses.size.should == 2
    end
  
    should "be embedded in document on save" do
      sb = Address.new(:city => 'South Bend', :state => 'IN')
      chi = Address.new(:city => 'Chicago', :state => 'IL')
      instance = @document.new
      instance.addresses << sb
      instance.addresses << chi
      instance.save
    
      from_db = @document.find(instance.id)
      from_db.addresses.size.should == 2
      from_db.addresses[0].should == sb
      from_db.addresses[1].should == chi
    end    
  end
end