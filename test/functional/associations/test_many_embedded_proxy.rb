require 'test_helper'
require 'models'

class ManyEmbeddedProxyTest < Test::Unit::TestCase
  def setup
    Project.collection.remove
    RealPerson.collection.remove
  end
    
  should "default reader to empty array" do
    Project.new.addresses.should == []
  end
  
  should "allow adding to association like it was an array" do
    project = Project.new
    project.addresses << Address.new
    project.addresses.push Address.new
    project.addresses.size.should == 2
  end

  should "be embedded in document on save" do
    sb = Address.new(:city => 'South Bend', :state => 'IN')
    chi = Address.new(:city => 'Chicago', :state => 'IL')
    project = Project.new
    project.addresses << sb
    project.addresses << chi
    project.save

    project.reload
    project.addresses.size.should == 2
    project.addresses[0].should == sb
    project.addresses[1].should == chi
  end
  
  should "allow embedding arbitrarily deep" do
    @document = Doc do
      key :person, Person
    end
    
    meg = Person.new(:name => "Meg")
    meg.child = Person.new(:name => "Steve")
    meg.child.child = Person.new(:name => "Linda")
    
    doc = @document.new(:person => meg)
    doc.save
    
    doc.reload
    doc.person.name.should == 'Meg'
    doc.person.child.name.should == 'Steve'
    doc.person.child.child.name.should == 'Linda'
  end
  
  should "allow assignment of 'many' embedded documents using a hash" do
    person_attributes = { 
      "name" => "Mr. Pet Lover", 
      "pets" => [
        {"name" => "Jimmy", "species" => "Cocker Spainel"},
        {"name" => "Sasha", "species" => "Siberian Husky"}, 
      ] 
    }
    
    pet_lover = RealPerson.new(person_attributes)
    pet_lover.name.should == "Mr. Pet Lover"
    pet_lover.pets[0].name.should == "Jimmy"
    pet_lover.pets[0].species.should == "Cocker Spainel"
    pet_lover.pets[1].name.should == "Sasha"
    pet_lover.pets[1].species.should == "Siberian Husky"
    pet_lover.save.should be_true
    
    pet_lover.reload
    pet_lover.name.should == "Mr. Pet Lover"
    pet_lover.pets[0].name.should == "Jimmy"
    pet_lover.pets[0].species.should == "Cocker Spainel"
    pet_lover.pets[1].name.should == "Sasha"
    pet_lover.pets[1].species.should == "Siberian Husky"
  end

  context "embedding many embedded documents" do
    setup do
      @document = Doc do
        many :people
      end
    end

    should "persist all embedded documents" do
      meg    = Person.new(:name => "Meg")
      sparky = Pet.new(:name => "Sparky", :species => "Dog")
      koda   = Pet.new(:name => "Koda", :species => "Dog")

      doc = @document.new
      meg.pets << sparky
      meg.pets << koda
      doc.people << meg
      doc.save

      doc.reload
      doc.people.first.name.should == "Meg"
      doc.people.first.pets.should_not == []
      doc.people.first.pets.first.name.should == "Sparky"
      doc.people.first.pets.first.species.should == "Dog"
      doc.people.first.pets[1].name.should == "Koda"
      doc.people.first.pets[1].species.should == "Dog"
    end

    should "create a reference to the root document for all embedded documents before save" do
      meg    = Person.new(:name => "Meg")
      sparky = Pet.new(:name => "Sparky", :species => "Dog")
      doc    = @document.new
      doc.people << meg
      meg.pets << sparky

      doc.people.first._root_document.should == doc
      doc.people.first.pets.first._root_document.should == doc
    end

    should "create a reference to the root document for all embedded documents" do
      sparky = Pet.new(:name => "Sparky", :species => "Dog")
      meg    = Person.new(:name => "Meg", :pets => [sparky])
      doc    = @document.new
      doc.people << meg
      doc.save

      doc.reload
      doc.people.first._root_document.should == doc
      doc.people.first.pets.first._root_document.should == doc
    end
  end
  
  should "allow finding by id" do
    sparky = Pet.new(:name => "Sparky", :species => "Dog")
    meg    = Person.new(:name => "Meg", :pets => [sparky])
    
    meg.pets.find(sparky._id).should     == sparky  # oid
    meg.pets.find(sparky.id.to_s).should == sparky  # string
  end
  
  context "extending the association" do
    setup do
      @address_class = EDoc do
        key :address, String
        key :city, String
        key :state, String
        key :zip, Integer
      end
      
      @project_class = Doc do
        key :name, String
      end
    end
    
    should "work using a block passed to many" do
      @project_class.many :addresses, :class => @address_class do
        def find_all_by_state(state)
          find_all { |a| a.state == state }
        end
      end
      
      addr1 = @address_class.new(:address => "Gate-3 Lankershim Blvd.", :city => "Universal City", :state => "CA", :zip => "91608")
      addr2 = @address_class.new(:address => "3000 W. Alameda Ave.", :city => "Burbank", :state => "CA", :zip => "91523")
      addr3 = @address_class.new(:address => "111 Some Ln", :city => "Nashville", :state => "TN", :zip => "37211")
      project = @project_class.create(:name => "Some Project", :addresses => [addr1, addr2, addr3])
      
      project.addresses.find_all_by_state("CA").should == [addr1, addr2]
    end
  
    should "work using many's :extend option" do
      module FindByCity
        def find_by_city(city)
          find_all { |a| a.city == city }
        end
      end
      @project_class.many :addresses, :class => @address_class, :extend => FindByCity
      
      addr1 = @address_class.new(:address => "Gate-3 Lankershim Blvd.", :city => "Universal City", :state => "CA", :zip => "91608")
      addr2 = @address_class.new(:address => "3000 W. Alameda Ave.", :city => "Burbank", :state => "CA", :zip => "91523")
      addr3 = @address_class.new(:address => "111 Some Ln", :city => "Nashville", :state => "TN", :zip => "37211")
      project = @project_class.create(:name => "Some Project", :addresses => [addr1, addr2, addr3])
      
      project.addresses.find_by_city('Burbank').should == [addr2]
    end
  end
end