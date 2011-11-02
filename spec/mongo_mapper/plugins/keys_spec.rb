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

  context ".new with no id and _id of type integer" do
    it "should not error" do
      lambda {
        klass = Doc() do
          key :_id, Integer
        end
        # No sensible default id for integer, people better pass them in if they user this
        silence_stderr { klass.new.id.should be_nil }
      }.should_not raise_error
    end
  end

  context ".key?(:symbol)" do
    it "should be true if document has key" do
      Address.key?(:city).should be_true
    end

    it "should be false if document does not have key" do
      Address.key?(:foo).should be_false
    end
  end

  context ".key?('string')" do
    it "should be true if document has key" do
      Address.key?('city').should be_true
    end

    it "should be false if document does not have key" do
      Address.key?('foo').should be_false
    end
  end

  context ".new (from database)" do
    before do
      @klass = Doc do
        key :user, Hash

        def user=(user)
          super(:id => user.id, :name => user.name)
        end
      end

      user_class = Struct.new(:id, :name)
      @klass.create(:user => user_class.new(1, 'John Nunemaker'))
    end

    it "should use []= for keys instead of public writer" do
      lambda {
        doc = @klass.first
        doc.user['id'].should   == 1
        doc.user['name'].should == 'John Nunemaker'
      }.should_not raise_error
    end
  end

  context ".load" do
    it "shouldreturn nil if argument is nil" do
      Doc().load(nil).should be_nil
    end
  end
end
