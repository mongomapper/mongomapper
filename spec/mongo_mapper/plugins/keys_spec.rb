require 'spec_helper'

describe MongoMapper::Plugins::Keys do
  let(:document) { Doc() }

  context "defaults" do
    it "should create id during initialization" do
      document.new._id.should be_instance_of(BSON::ObjectId)
    end

    it "should use default values if defined for keys" do
      document.key :active, Boolean, :default => true

      document.new.active.should be_true
      document.new(:active => false).active.should be_false
    end

    it "should use default values if defined even when custom data type" do
      document.key :window, WindowSize, :default => WindowSize.new(600, 480)

      document.new.window.should == WindowSize.new(600, 480)
    end
  end

  context "nil attributes" do
    before do
      document.key :name, String
      document.key :age, Integer
    end

    it "should list all the keys and default non nil attributes" do
     doc = document.new
     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id']
    end

    it "should list all the keys and non nil attributes" do
     doc = document.new(:name => "John")
     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id','name']
    end

    it "should list all the keys and pickup changed nil attributes" do
     doc = document.new(:name => "John")
     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id','name']

     doc.name = nil

     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id']
    end

    it "should list all the keys and pickup changed nil and non-nil attributes" do
     doc = document.new(:name => "John")
     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id','name']

     doc.name = nil
     doc.age = 12

     doc.keys.keys.sort.should == ['_id', 'age', 'name']
     doc.attributes.keys.sort.should == ['_id','age']
    end

  end


end
