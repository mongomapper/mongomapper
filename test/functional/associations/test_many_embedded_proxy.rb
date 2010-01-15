require 'test_helper'
require 'models'

class ManyEmbeddedProxyTest < Test::Unit::TestCase
  def setup
    @comment_class = EDoc do
      key :name, String
      key :body, String
    end
    @post_class = Doc do
      key :title, String
    end
    @post_class.many :comments, :class => @comment_class
    
    @pet_class = EDoc do
      key :name, String
    end
    @pet_class.embedded_in :person
    @person_class = EDoc do
      key :name, String
    end
    @person_class.key :child, @person_class
    @person_class.many :pets, :class => @pet_class
    
    @owner_class = Doc do
      key :name, String
    end
    @owner_class.many :pets, :class => @pet_class
  end
    
  should "default reader to empty array" do
    @post_class.new.comments.should == []
  end
  
  should "allow adding to association like it was an array" do
    post = @post_class.new
    post.comments << @comment_class.new
    post.comments.push @comment_class.new
    post.comments.size.should == 2
  end

  should "be embedded in document on save" do
    frank = @comment_class.new(:name => 'Frank', :body => 'Hi!')
    bill = @comment_class.new(:name => 'Bill', :body => 'Hi!')
    post = @post_class.new
    post.comments << frank
    post.comments << bill
    post.save

    post.reload
    post.comments.size.should == 2
    post.comments[0].should == frank
    post.comments[0].new?.should == false
    post.comments[1].should == bill
    post.comments[1].new?.should == false
  end
  
  should "allow embedding arbitrarily deep" do
    @klass = Doc()
    @klass.key :person, @person_class
    
    meg             = @person_class.new(:name => 'Meg')
    meg.child       = @person_class.new(:name => 'Steve')
    meg.child.child = @person_class.new(:name => 'Linda')
    
    doc = @klass.new(:person => meg)
    doc.save
    doc.reload
    
    doc.person.name.should == 'Meg'
    doc.person.child.name.should == 'Steve'
    doc.person.child.child.name.should == 'Linda'
  end
  
  should "allow assignment of many embedded documents using a hash" do
    person_attributes = { 
      'name' => 'Mr. Pet Lover', 
      'pets' => [
        {'name' => 'Jimmy', 'species' => 'Cocker Spainel'},
        {'name' => 'Sasha', 'species' => 'Siberian Husky'}, 
      ] 
    }
    
    owner = @owner_class.new(person_attributes)
    owner.name.should == 'Mr. Pet Lover'
    owner.pets[0].name.should == 'Jimmy'
    owner.pets[0].species.should == 'Cocker Spainel'
    owner.pets[1].name.should == 'Sasha'
    owner.pets[1].species.should == 'Siberian Husky'

    owner.save.should be_true
    owner.reload

    owner.name.should == 'Mr. Pet Lover'
    owner.pets[0].name.should == 'Jimmy'
    owner.pets[0].species.should == 'Cocker Spainel'
    owner.pets[1].name.should == 'Sasha'
    owner.pets[1].species.should == 'Siberian Husky'
  end

  context "embedding many embedded documents" do
    setup do
      @klass = Doc()
      @klass.many :people, :class => @person_class
    end

    should "persist all embedded documents" do
      meg = @person_class.new(:name => 'Meg', :pets => [
        @pet_class.new(:name => 'Sparky', :species => 'Dog'),
        @pet_class.new(:name => 'Koda', :species => 'Dog')
      ])
      
      doc = @klass.new
      doc.people << meg
      doc.save
      doc.reload
      
      doc.people.first.name.should == 'Meg'
      doc.people.first.pets.should_not == []
      doc.people.first.pets.first.name.should == 'Sparky'
      doc.people.first.pets.first.species.should == 'Dog'
      doc.people.first.pets[1].name.should == 'Koda'
      doc.people.first.pets[1].species.should == 'Dog'
    end

    should "create a reference to the root document for all embedded documents before save" do
      doc = @klass.new
      meg = @person_class.new(:name => 'Meg')
      pet = @pet_class.new(:name => 'Sparky', :species => 'Dog')
      
      doc.people << meg
      meg.pets << pet

      doc.people.first._root_document.should == doc
      doc.people.first.pets.first._root_document.should == doc
    end
    should "create a reference to the owning document for all embedded documents before save" do
      doc = @klass.new
      meg = @person_class.new(:name => 'Meg')
      pet = @pet_class.new(:name => 'Sparky', :species => 'Dog')
      
      doc.people << meg
      meg.pets << pet

      doc.people.first._parent_document.should == doc
      doc.people.first.pets.first._parent_document.should == doc.people.first
    end

    should "create a reference to the root document for all embedded documents" do
      sparky = @pet_class.new(:name => 'Sparky', :species => 'Dog')
      meg    = @person_class.new(:name => 'Meg', :pets => [sparky])
      doc    = @klass.new
      doc.people << meg
      doc.save

      doc.reload
      doc.people.first._root_document.should == doc
      doc.people.first.pets.first._root_document.should == doc
    end
    should "create a reference to the owning document for all embedded documents" do
      doc = @klass.new
      meg = @person_class.new(:name => 'Meg')
      pet = @pet_class.new(:name => 'Sparky', :species => 'Dog')
      
      doc.people << meg
      meg.pets << pet
      doc.save

      doc.reload
      doc.people.first._parent_document.should == doc
      doc.people.first.pets.first._parent_document.should == doc.people.first
    end

    should "create embedded_in relationship for embedded docs" do
      doc = @klass.new
      meg = @person_class.new(:name => 'Meg')
      pet = @pet_class.new(:name => 'Sparky', :species => 'Dog')
      
      doc.people << meg
      meg.pets << pet
      doc.save

      doc.reload
      doc.people.first.pets.first.person.should == doc.people.first
    end
  end
  
  should "allow finding by id" do
    sparky = @pet_class.new(:name => 'Sparky', :species => 'Dog')
    meg    = @owner_class.create(:name => 'Meg', :pets => [sparky])
    
    meg.pets.find(sparky._id).should     == sparky  # oid
    meg.pets.find(sparky.id.to_s).should == sparky  # string
  end
  
  context "count" do
    should "default to 0" do
      @owner_class.new.pets.count.should == 0
    end
    
    should "return correct count if any are embedded" do
      owner = @owner_class.new(:name => 'Meg')
      owner.pets = [@pet_class.new, @pet_class.new]
      owner.pets.count.should == 2
      owner.save
      owner.reload
      owner.pets.count.should == 2
    end
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