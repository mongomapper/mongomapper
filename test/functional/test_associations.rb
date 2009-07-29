require 'test_helper'
require 'models'

class AssociationsTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end
  
  context "Modularized Polymorphic Many Embedded" do
    should "set associations correctly" do
      fleet_attributes = { 
        "name" => "My Fleet", 
        "transports" => [
          {"_type" => "TrModels::Ambulance", "license_plate" => "GGG123", "icu" => true},
          {"_type" => "TrModels::Car", "license_plate" => "ABC123", "model" => "VW Golf", "year" => 2001}, 
          {"_type" => "TrModels::Car", "license_plate" => "DEF123", "model" => "Honda Accord", "year" => 2008},
        ] 
      }
      
      fleet = TrModels::Fleet.new(fleet_attributes)
      fleet.transports.size.should == 3
      fleet.transports[0].class.should == TrModels::Ambulance
      fleet.transports[0].license_plate.should == "GGG123"
      fleet.transports[0].icu.should be_true
      fleet.transports[1].class.should == TrModels::Car
      fleet.transports[1].license_plate.should == "ABC123"
      fleet.transports[1].model.should == "VW Golf"
      fleet.transports[1].year.should == 2001
      fleet.transports[2].class.should == TrModels::Car
      fleet.transports[2].license_plate.should == "DEF123"
      fleet.transports[2].model.should == "Honda Accord"
      fleet.transports[2].year.should == 2008      
      fleet.save.should be_true
      
      from_db = TrModels::Fleet.find(fleet.id)
      from_db.transports.size.should == 3
      from_db.transports[0].license_plate.should == "GGG123"
      from_db.transports[0].icu.should be_true
      from_db.transports[1].license_plate.should == "ABC123"
      from_db.transports[1].model.should == "VW Golf"
      from_db.transports[1].year.should == 2001
      from_db.transports[2].license_plate.should == "DEF123"
      from_db.transports[2].model.should == "Honda Accord"
      from_db.transports[2].year.should == 2008      
    end
    
    should "default reader to empty array" do
      fleet = TrModels::Fleet.new
      fleet.transports.should == []
    end
    
    should "allow adding to association like it was an array" do
      fleet = TrModels::Fleet.new
      fleet.transports << TrModels::Car.new
      fleet.transports.push TrModels::Bus.new
      fleet.transports.size.should == 2
    end
    
    should "store the association" do
      fleet = TrModels::Fleet.new
      fleet.transports = [TrModels::Car.new("license_plate" => "DCU2013", "model" => "Honda Civic")]
      fleet.save.should be_true
    
      from_db = TrModels::Fleet.find(fleet.id)
      from_db.transports.size.should == 1
      from_db.transports[0].license_plate.should == "DCU2013"
    end
    
    should "store different associations" do
      fleet = TrModels::Fleet.new
      fleet.transports = [
        TrModels::Car.new("license_plate" => "ABC1223", "model" => "Honda Civic", "year" => 2003),
        TrModels::Bus.new("license_plate" => "XYZ9090", "max_passengers" => 51),
        TrModels::Ambulance.new("license_plate" => "HDD3030", "icu" => true)
      ]
      fleet.save.should be_true
    
      from_db = TrModels::Fleet.find(fleet.id)
      from_db.transports.size.should == 3
      from_db.transports[0].license_plate.should == "ABC1223"
      from_db.transports[0].model.should == "Honda Civic"
      from_db.transports[0].year.should == 2003
      from_db.transports[1].license_plate.should == "XYZ9090"
      from_db.transports[1].max_passengers.should == 51
      from_db.transports[2].license_plate.should == "HDD3030"
      from_db.transports[2].icu.should == true
    end
  end

  context "Polymorphic Many Embedded" do
    should "default reader to empty array" do
      catalog = Catalog.new
      catalog.medias.should == []
    end
  
    should "allow adding to association like it was an array" do
      catalog = Catalog.new
      catalog.medias << Video.new
      catalog.medias.push Video.new
      catalog.medias.size.should == 2
    end
  
    should "store the association" do
      catalog = Catalog.new
      catalog.medias = [Video.new("file" => "video.mpg", "length" => 3600)]
      catalog.save.should be_true
  
      from_db = Catalog.find(catalog.id)
      from_db.medias.size.should == 1
      from_db.medias[0].file.should == "video.mpg"
    end
  
    should "store different associations" do      
      catalog = Catalog.new
      catalog.medias = [
        Video.new("file" => "video.mpg", "length" => 3600),
        Music.new("file" => "music.mp3", "bitrate" => "128kbps"),
        Image.new("file" => "image.png", "width" => 800, "height" => 600)
      ]
      catalog.save.should be_true
      
      from_db = Catalog.find(catalog.id)
      from_db.medias.size.should == 3
      from_db.medias[0].file.should == "video.mpg"
      from_db.medias[0].length.should == 3600
      from_db.medias[1].file.should == "music.mp3"
      from_db.medias[1].bitrate.should == "128kbps"
      from_db.medias[2].file.should == "image.png"
      from_db.medias[2].width.should == 800
      from_db.medias[2].height.should == 600
    end
  end
  
  context "Polymorphic Belongs To" do
    should "default to nil" do
      status = Status.new
      status.target.should be_nil
    end
  
    should "store the association" do
      status = Status.new
      project = Project.new(:name => "mongomapper")
      status.target = project
      status.save.should be_true
  
      from_db = Status.find(status.id)
      from_db.target.should_not be_nil
      from_db.target_id.should == project.id
      from_db.target_type.should == "Project"
      from_db.target.name.should == "mongomapper"
    end
  
    should "unset the association" do
      status = Status.new
      project = Project.new(:name => "mongomapper")
      status.target = project
      status.save.should be_true
  
      from_db = Status.find(status.id)
      from_db.target = nil
      from_db.target_type.should be_nil
      from_db.target_id.should be_nil
      from_db.target.should be_nil
    end
  end
  
  context "Belongs To" do
    should "default to nil" do
      status = Status.new
      status.project.should be_nil
    end
    
    should "store the association" do
      status = Status.new
      project = Project.new(:name => "mongomapper")
      status.project = project
      status.save.should be_true
      
      from_db = Status.find(status.id)
      from_db.project.should_not be_nil
      from_db.project.name.should == "mongomapper"
    end
    
    should "unset the association" do
      status = Status.new
      project = Project.new(:name => "mongomapper")
      status.project = project
      status.save.should be_true
      
      from_db = Status.find(status.id)
      from_db.project = nil
      from_db.project.should be_nil
    end
  end
  
  context "Many documents" do    
    should "default reader to empty array" do
      project = Project.new
      project.statuses.should == []
    end
  
    should "allow adding to association like it was an array" do
      project = Project.new
      project.statuses << Status.new
      project.statuses.push Status.new
      project.statuses.size.should == 2
    end
  
    should "store the association" do
      project = Project.new
      project.statuses = [Status.new("name" => "ready")]
      project.save.should be_true
  
      from_db = Project.find(project.id)
      from_db.statuses.size.should == 1
      from_db.statuses[0].name.should == "ready"
    end
    
    context "Finding scoped to association" do
      setup do
        @project1          = Project.new(:name => 'Project 1')
        @brand_new         = Status.create(:name => 'New')
        @complete          = Status.create(:name => 'Complete')
        @project1.statuses = [@brand_new, @complete]
        @project1.save
        
        @project2          = Project.create(:name => 'Project 2')
        @in_progress       = Status.create(:name => 'In Progress')
        @archived          = Status.create(:name => 'Archived')
        @another_complete  = Status.create(:name => 'Complete')
        @project2.statuses = [@in_progress, @archived, @another_complete]
        @project2.save
      end
      
      context "with :all" do
        should "work" do
          @project1.statuses.find(:all).should == [@brand_new, @complete]
        end
        
        should "work with conditions" do
          statuses = @project1.statuses.find(:all, :conditions => {'name' => 'Complete'})
          statuses.should == [@complete]
        end
        
        should "work with order" do
          statuses = @project1.statuses.find(:all, :order => 'name asc')
          statuses.should == [@complete, @brand_new]
        end
      end

      context "with #all" do
        should "work" do
          @project1.statuses.all.should == [@brand_new, @complete]
        end
        
        should "work with conditions" do
          statuses = @project1.statuses.all(:conditions => {'name' => 'Complete'})
          statuses.should == [@complete]
        end
        
        should "work with order" do
          statuses = @project1.statuses.all(:order => 'name asc')
          statuses.should == [@complete, @brand_new]
        end
      end
      
      context "with :first" do
        should "work" do
          @project1.statuses.find(:first).should == @brand_new
        end
        
        should "work with conditions" do
          status = @project1.statuses.find(:first, :conditions => {:name => 'Complete'})
          status.should == @complete
        end
      end
      
      context "with #first" do
        should "work" do
          @project1.statuses.first.should == @brand_new
        end
        
        should "work with conditions" do
          status = @project1.statuses.first(:conditions => {:name => 'Complete'})
          status.should == @complete
        end
      end
      
      context "with :last" do
        should "work" do
          @project1.statuses.find(:last).should == @complete
        end
        
        should "work with conditions" do
          status = @project1.statuses.find(:last, :conditions => {:name => 'New'})
          status.should == @brand_new
        end
      end
      
      context "with #last" do
        should "work" do
          @project1.statuses.last.should == @complete
        end
        
        should "work with conditions" do
          status = @project1.statuses.last(:conditions => {:name => 'New'})
          status.should == @brand_new
        end
      end
      
      context "with one id" do
        should "work for id in association" do
          @project1.statuses.find(@complete.id).should == @complete
        end
        
        should "not work for id not in association" do
          lambda {
            @project1.statuses.find(@archived.id)
          }.should raise_error(MongoMapper::DocumentNotFound)
        end
      end
      
      context "with multiple ids" do
        should "work for ids in association" do
          statuses = @project1.statuses.find(@brand_new.id, @complete.id)
          statuses.should == [@brand_new, @complete]
        end
        
        should "not work for ids not in association" do
          lambda {
            @project1.statuses.find(@brand_new.id, @complete.id, @archived.id)
          }.should raise_error(MongoMapper::DocumentNotFound)
        end
      end
      
      context "with #paginate" do
        setup do
          @statuses = @project2.statuses.paginate(:per_page => 2, :page => 1)
        end
        
        should "return total pages" do
          @statuses.total_pages.should == 2
        end
        
        should "return total entries" do
          @statuses.total_entries.should == 3
        end
        
        should "return the subject" do
          @statuses.should == [@in_progress, @archived]
        end
      end
    end
  end
  
  context "Many polymorphic documents" do
    should "default reader to empty array" do
      Room.new.messages.should == []
    end
    
    should "add type key to polymorphic class base" do
      Message.keys.keys.should include('_type')
    end
    
    should "allow adding to assiciation like it was an array" do
      room = Room.new
      room.messages << Enter.new(:body => 'John entered room')
      room.messages.push Exit.new(:body => 'John exited room')
      room.messages.size.should == 2
    end
    
    should "store the association" do
      room = Room.create(:name => 'Lounge')
      
      lambda {
        room.messages = [
          Enter.new(:body => 'John entered room'),
          Chat.new(:body => 'Heyyyoooo!'),
          Exit.new(:body => 'John exited room')
        ]
      }.should change { Message.count }.by(3)
      
      from_db = Room.find(room.id)
      from_db.messages.size.should == 3
      from_db.messages[0].body.should == 'John entered room'
      from_db.messages[1].body.should == 'Heyyyoooo!'
      from_db.messages[2].body.should == 'John exited room'
    end
  end
  
  context "Many embedded documents" do
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
  
      from_db = Project.find(project.id)
      from_db.addresses.size.should == 2
      from_db.addresses[0].should == sb
      from_db.addresses[1].should == chi
    end
    
    should "allow embedding arbitrarily deep" do
      @document = Class.new do
        include MongoMapper::Document
        key :person, Person
      end
      @document.collection.clear
      
      meg = Person.new(:name => "Meg")
      meg.child = Person.new(:name => "Steve")
      meg.child.child = Person.new(:name => "Linda")
      
      doc = @document.new(:person => meg)
      doc.save
      
      from_db = @document.find(doc.id)
      from_db.person.name.should == 'Meg'
      from_db.person.child.name.should == 'Steve'
      from_db.person.child.child.name.should == 'Linda'
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
      
      from_db = RealPerson.find(pet_lover.id)
      from_db.name.should == "Mr. Pet Lover"
      from_db.pets[0].name.should == "Jimmy"
      from_db.pets[0].species.should == "Cocker Spainel"
      from_db.pets[1].name.should == "Sasha"
      from_db.pets[1].species.should == "Siberian Husky"
    end
    
    should "allow saving embedded documents in 'many' embedded documents" do
      @document = Class.new do
        include MongoMapper::Document
        many :people
      end
      @document.collection.clear
      
      meg = Person.new(:name => "Meg")
      sparky = Pet.new(:name => "Sparky", :species => "Dog")
      koda = Pet.new(:name => "Koda", :species => "Dog")
      
      doc = @document.new
      
      meg.pets << sparky
      meg.pets << koda
      
      doc.people << meg
      doc.save
      
      from_db = @document.find(doc.id)
      from_db.people.first.name.should == "Meg"
      from_db.people.first.pets.should_not == []
      from_db.people.first.pets.first.name.should == "Sparky"
      from_db.people.first.pets.first.species.should == "Dog"
      from_db.people.first.pets[1].name.should == "Koda"
      from_db.people.first.pets[1].species.should == "Dog"
    end
  end
  
  context "Changing association class names" do
    should "work for many and belongs to" do
      class AwesomeUser
        include MongoMapper::Document
        many :posts, :class_name => 'AssociationsTest::AwesomePost', :foreign_key => :creator_id
      end
      
      class AwesomeTag
        include MongoMapper::EmbeddedDocument
        key :name, String
        belongs_to :post, :class_name => 'AssociationsTest::AwesomeUser'
      end
      
      class AwesomePost
        include MongoMapper::Document
        belongs_to :creator, :class_name => 'AssociationsTest::AwesomeUser'
        many :tags, :class_name => 'AssociationsTest::AwesomeTag', :foreign_key => :post_id
      end
      
      AwesomeUser.collection.clear
      AwesomePost.collection.clear
      
      user = AwesomeUser.create
      tag1 = AwesomeTag.new(:name => 'awesome')
      tag2 = AwesomeTag.new(:name => 'grand')
      post1 = AwesomePost.create(:creator => user, :tags => [tag1])
      post2 = AwesomePost.create(:creator => user, :tags => [tag2])
      user.posts.should == [post1, post2]
      
      post1_from_db = AwesomePost.find(post1.id)
      post1_from_db.tags.should == [tag1]
    end
  end
end