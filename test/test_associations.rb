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

class AssociationsTest < Test::Unit::TestCase
  def setup
    Project.collection.clear
    Status.collection.clear
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
  end
end