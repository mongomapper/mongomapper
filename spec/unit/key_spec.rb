require 'spec_helper'


class FooType < Struct.new(:bar)
  def self.to_mongo(value)
    'to_mongo'
  end

  def self.from_mongo(value)
    'from_mongo'
  end
end

describe "Key" do
  Key = MongoMapper::Plugins::Keys::Key

  context "Initializing a new key" do
    it "should allow setting the name" do
      Key.new(:foo, String).name.should == 'foo'
    end

    it "should allow setting the type" do
      Key.new(:foo, Integer).type.should be(Integer)
    end

    it "should allow setting options" do
      Key.new(:foo, Integer, :required => true).options[:required].should be(true)
    end

    it "should default options to {}" do
      Key.new(:foo, Integer, nil).options.should == {}
    end

    it "should symbolize option keys" do
      Key.new(:foo, Integer, 'required' => true).options[:required].should be(true)
    end

    it "should work with just name" do
      key = Key.new(:foo)
      key.name.should == 'foo'
    end

    it "should work with name and type" do
      key = Key.new(:foo, String)
      key.name.should == 'foo'
      key.type.should == String
    end

    it "should work with name, type, and options" do
      key = Key.new(:foo, String, :required => true)
      key.name.should == 'foo'
      key.type.should == String
      key.options[:required].should be_truthy
    end

    it "should work with name and options" do
      key = Key.new(:foo, :required => true)
      key.name.should == 'foo'
      key.options[:required].should be_truthy
    end

    it "should not permit reserved names" do
      expect { Key.new(:id) }.to raise_error(/reserved/)
    end

    it "should not permit bad names" do
      expect { Key.new(:"id.bar") }.to raise_error(/must match/)
    end

    it "should permit bad names if __dynamic" do
      expect { Key.new(:"id.bar", :__dynamic => true) }.to_not raise_error
    end

    it "should permit bad names if it is not to create accessors" do
      expect { Key.new(:"id.bar", :accessors => :skip) }.to_not raise_error
    end
  end

  context "A key" do
    it "should be equal to another key with same name and type" do
      Key.new(:name, String).should == Key.new(:name, String)
    end

    it "should not be equal to another key with different name" do
      Key.new(:name, String).should_not == Key.new(:foo, String)
    end

    it "should not be equal to another key with different type" do
      Key.new(:name, String).should_not == Key.new(:name, Integer)
    end

    it "should know if it is a embedded_document" do
      Key.new(:name, EDoc()).embeddable?.should be_truthy
    end

    it "should know if it is not a embedded_document" do
      Key.new(:name, String).embeddable?.should be_falsey
    end

    it "should know if it is a number" do
      Key.new(:age, Integer).number?.should be_truthy
      Key.new(:age, Float).number?.should be_truthy
    end

    it "should know if it is not a number" do
      Key.new(:age, String).number?.should be_falsey
    end
  end

  context "for an array with :typecast option" do
    before  { @key = Key.new(:user_ids, Array, :typecast => 'ObjectId') }
    subject { @key }

    it "should cast each element correctly" do
      ids = [BSON::ObjectId.new, BSON::ObjectId.new, BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
      subject.set(ids).should == ids.map { |id| ObjectId.to_mongo(id) }
    end
  end

  context "for an array with :typecast option of Date" do
    before  { @key = Key.new(:dates, Array, :typecast => 'Date') }
    subject { @key }

    it "should cast each element correctly when get" do
      dates = [Date.yesterday, Date.today, Date.tomorrow.to_s]
      subject.get(dates).should == dates.map { |date| Date.from_mongo(date) }
    end

    it "should cast each element correctly when set" do
      dates = [Date.yesterday, Date.today, Date.tomorrow.to_s]
      subject.set(dates).should == dates.map { |date| Date.to_mongo(date) }
    end
  end

  context "for a set with :typecast option" do
    before  { @key = Key.new(:user_ids, Set, :typecast => 'ObjectId') }
    subject { @key }

    it "should cast each element correctly" do
      ids = [BSON::ObjectId.new, BSON::ObjectId.new, BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
      subject.set(ids).should == ids.map { |id| ObjectId.to_mongo(id) }
    end
  end

  context "with the :attributes option" do
    subject { @key }
    before { @key = Key.new(:test, String, :accessors => accessor) }

    context "with :read" do
      let(:accessor) { :read }
      its(:read_accessor?) { should be_truthy }
      its(:write_accessor?) { should be_falsey }
      its(:predicate_accessor?) { should be_falsey }
    end

    context "with :write" do
      let(:accessor) { :write }
      its(:read_accessor?) { should be_falsey }
      its(:write_accessor?) { should be_truthy }
      its(:predicate_accessor?) { should be_falsey }
    end

    context "with :predicate" do
      let(:accessor) { :predicate }
      its(:read_accessor?) { should be_falsey }
      its(:write_accessor?) { should be_falsey }
      its(:predicate_accessor?) { should be_truthy }
    end

    context "with an array of options" do
      let(:accessor) { [:read, :write] }

      its(:read_accessor?) { should be_truthy }
      its(:write_accessor?) { should be_truthy }
      its(:predicate_accessor?) { should be_falsey }
    end
  end

  context "setting a value with a custom type" do
    it "should correctly typecast" do
      key = Key.new(:foo, FooType)
      key.set("something").should == 'to_mongo'
    end

    it "should correctly typecast if object of that type is given" do
      key = Key.new(:foo, FooType)
      key.set(FooType.new('something')).should == 'to_mongo'
    end
  end

  context "getting a value with a custom type" do
    it "should use #from_mongo to convert back to custom type" do
      key = Key.new(:foo, FooType)
      key.get('something').should == 'from_mongo'
    end
  end

  context "getting a value" do
    it "should work with a type" do
      key = Key.new(:foo, String)
      key.get('bar').should == 'bar'
    end

    it "should work without type" do
      key = Key.new(:foo)
      key.get([1, '2']).should == [1, '2']
      key.get(false).should == false
      key.get({}).should == {}
    end

    context "for a embedded_document" do
      it "should default to nil" do
        key = Key.new(:foo, Address)
        key.get(nil).should be_nil
      end

      it "should return instance if instance" do
        address = Address.new(:city => 'South Bend', :state => 'IN', :zip => 46544)
        key = Key.new(:foo, Address)
        key.get(address).should == address
      end
    end
  end

  context "with a default set" do
    before do
      @key = Key.new(:foo, String, :default => 'baz')
    end

    context "#get" do
      it "should return nil" do
        @key.get(nil).should == nil
      end

      it "should return value if not blank" do
        @key.get('foobar').should == 'foobar'
      end

      it "should return default value if name is _id and value nil" do
        id = BSON::ObjectId.new
        key = Key.new(:_id, ObjectId, :default => lambda { id })
        key.get(nil).should == id
      end
    end

    context "#default_value" do
      it "should return default value" do
        @key.default_value.should == 'baz'
      end

      it "should return a dup of the default value" do
        @key.default_value.replace('bar')
        @key.default_value.should == 'baz'
      end

      it "should work with Boolean type and false value" do
        Key.new(:active, Boolean, :default => false).default_value.should be_falsey
      end

      it "should work with Boolean type and true value" do
        Key.new(:active, Boolean, :default => true).default_value.should be_truthy
      end

      it "should work with Array values" do
        Key.new(:active, Array, :default => []).default_value.should == []
      end

      it "should work with procs" do
         Key.new(:foo, String, :default => lambda { return 'hello world' }).default_value.should == "hello world"
      end
    end
  end
end # KeyTest
