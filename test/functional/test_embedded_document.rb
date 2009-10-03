require 'test_helper'
require 'models'

class EmbeddedDocumentTest < Test::Unit::TestCase    
  should "save the embedded document" do
    person = RealPerson.create
    
    pet = Pet.new :name => 'sparky'
    person.pets << pet
    pet.save
    
    doc = RealPerson.find(person.id)
    doc.pets.first.should == pet
  end

  should "update_attributes on the embedded document" do
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