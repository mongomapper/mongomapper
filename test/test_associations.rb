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
    @document = Project
    @document.destroy_all
  end

  context "Polymorphic Belongs To" do
    setup do
      @document = Status
      @document.destroy_all
    end

    should "default to nil" do
      doc = @document.new
      doc.target.should be_nil
    end

    should "store the association" do
      doc = @document.new
      project = Project.new(:name => "mongomapper")
      doc.target = project
      doc.save.should_not be_nil

      from_db = @document.find(doc.id)
      from_db.target.should_not be_nil
      from_db.target_id.should == project.id
      from_db.target_type.should == "Project"
      from_db.target.name.should == "mongomapper"

      from_db.destroy
    end

    should "unset the association" do
      doc = @document.new
      project = Project.new(:name => "mongomapper")
      doc.target = project
      doc.save.should_not be_nil

      from_db = @document.find(doc.id)
      from_db.target = nil
      from_db.target_type.should be_nil
      from_db.target_id.should be_nil
      from_db.target.should be_nil

      from_db.destroy
    end
  end

  context "Belongs To" do
    setup do
      @document = Status
      @document.destroy_all
    end

    should "default to nil" do
      doc = @document.new
      doc.project.should be_nil
    end

    should "store the association" do
      doc = @document.new
      project = Project.new(:name => "mongomapper")
      doc.project = project
      doc.save.should_not be_nil

      from_db = @document.find(doc.id)
      from_db.project.should_not be_nil
      from_db.project.name.should == "mongomapper"

      from_db.destroy
    end

    should "unset the association" do
      doc = @document.new
      project = Project.new(:name => "mongomapper")
      doc.project = project
      doc.save.should_not be_nil

      from_db = @document.find(doc.id)
      from_db.project = nil
      from_db.project.should be_nil

      from_db.destroy
    end
  end

  context "Many documents" do
    setup do
    end

    should "default reader to empty array" do
      instance = @document.new
      instance.statuses.should == []
    end

    should "allow adding to association like it was an array" do
      instance = @document.new

      instance.statuses << Status.new
      instance.statuses.push Status.new
      instance.statuses.size.should == 2
    end

    should "store the association" do
      instance = @document.new
      instance.statuses = [Status.new("name" => "ready")]
      instance.save.should_not be_nil

      from_db = @document.find(instance.id)
      from_db.statuses.size.should == 1
      from_db.statuses[0].name.should == "ready"
      from_db.destroy
    end
  end

  context "Many embedded documents" do
    setup do
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

      from_db.destroy
    end
  end
end