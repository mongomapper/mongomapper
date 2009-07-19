require 'test_helper'

class Address
  include MongoMapper::EmbeddedDocument

  key :address, String
  key :city,    String
  key :state,   String
  key :zip,     Integer
end

class Project
  include MongoMapper::Document

  key :name, String

  many :statuses
  many :addresses
end

class Status
  include MongoMapper::Document

  belongs_to :project
  belongs_to :target, :polymorphic => true

  key :name, String
end

class Person
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :child, Person
  
  many :pets
end

class Pet
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :species, String
end

class Media
  include MongoMapper::EmbeddedDocument
  key :file, String
end

class Video < Media
  key :length, Integer
end

class Image < Media
  key :width, Integer
  key :height, Integer
end

class Music < Media
  key :bitrate, String
end

class Catalog
  include MongoMapper::Document
  
  many :medias, :polymorphic => true
end

module TrModels
  class Transport
    include MongoMapper::EmbeddedDocument
    key :license_plate, String
  end
  
  class Car < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :model, String
    key :year, Integer
  end
  
  class Bus < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :max_passengers, Integer
  end
  
  class Ambulance < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    key :icu, Boolean
  end
  
  class Fleet
    include MongoMapper::Document
    many :transports, :polymorphic => true, :class_name => "TrModels::Transport"
    key :name, String
  end
end

class AssociationsTest < Test::Unit::TestCase
  def setup
    Project.collection.clear
    Status.collection.clear
  end
  
  context "Nested Polymorphic Many" do
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

  context "Polymorphic Many" do
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
  end

  context "Many embedded documents" do
    should "default reader to empty array" do
      project = Project.new
      project.addresses.should == []
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
    
    should "allow saving embedded documents in 'many' embedded documents" do
      @document = Class.new do
        include MongoMapper::Document
        
        many :people
      end
      
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
end