require 'test_helper'
require 'models'

class FooType < Struct.new(:bar)
  def self.to_mongo(value)
    'to_mongo'
  end

  def self.from_mongo(value)
    'from_mongo'
  end
end

class KeyTest < Test::Unit::TestCase
  Key = MongoMapper::Plugins::Keys::Key

  context "Initializing a new key" do
    should "allow setting the name" do
      Key.new(:foo, String).name.should == 'foo'
    end

    should "allow setting the type" do
      Key.new(:foo, Integer).type.should be(Integer)
    end

    should "allow setting options" do
      Key.new(:foo, Integer, :required => true).options[:required].should be(true)
    end

    should "default options to {}" do
      Key.new(:foo, Integer, nil).options.should == {}
    end

    should "symbolize option keys" do
      Key.new(:foo, Integer, 'required' => true).options[:required].should be(true)
    end

    should "work with just name" do
      key = Key.new(:foo)
      key.name.should == 'foo'
    end

    should "work with name and type" do
      key = Key.new(:foo, String)
      key.name.should == 'foo'
      key.type.should == String
    end

    should "work with name, type, and options" do
      key = Key.new(:foo, String, :required => true)
      key.name.should == 'foo'
      key.type.should == String
      key.options[:required].should be_true
    end

    should "work with name and options" do
      key = Key.new(:foo, :required => true)
      key.name.should == 'foo'
      key.options[:required].should be_true
    end
  end

  context "A key" do
    should "be equal to another key with same name and type" do
      Key.new(:name, String).should == Key.new(:name, String)
    end

    should "not be equal to another key with different name" do
      Key.new(:name, String).should_not == Key.new(:foo, String)
    end

    should "not be equal to another key with different type" do
      Key.new(:name, String).should_not == Key.new(:name, Integer)
    end

    should "know if it is a embedded_document" do
      Key.new(:name, EDoc()).embeddable?.should be_true
    end

    should "know if it is not a embedded_document" do
      Key.new(:name, String).embeddable?.should be_false
    end

    should "know if it is a number" do
      Key.new(:age, Integer).number?.should be_true
      Key.new(:age, Float).number?.should be_true
    end

    should "know if it is not a number" do
      Key.new(:age, String).number?.should be_false
    end
  end

  context "for an array with :typecast option" do
    setup   { @key = Key.new(:user_ids, Array, :typecast => 'ObjectId') }
    subject { @key }

    should "cast each element correctly" do
      ids = [BSON::ObjectId.new, BSON::ObjectId.new, BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
      subject.set(ids).should == ids.map { |id| ObjectId.to_mongo(id) }
    end
  end

  context "for an array with :typecast option of Date" do
    setup   { @key = Key.new(:dates, Array, :typecast => 'Date') }
    subject { @key }

    should "cast each element correctly when get" do
      dates = [Date.yesterday, Date.today, Date.tomorrow.to_s]
      subject.get(dates).should == dates.map { |date| Date.from_mongo(date) }
    end

    should "cast each element correctly when set" do
      dates = [Date.yesterday, Date.today, Date.tomorrow.to_s]
      subject.set(dates).should == dates.map { |date| Date.to_mongo(date) }
    end
  end

  context "for a set with :typecast option" do
    setup   { @key = Key.new(:user_ids, Set, :typecast => 'ObjectId') }
    subject { @key }

    should "cast each element correctly" do
      ids = [BSON::ObjectId.new, BSON::ObjectId.new, BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
      subject.set(ids).should == ids.map { |id| ObjectId.to_mongo(id) }
    end
  end

  context "setting a value with a custom type" do
    should "correctly typecast" do
      key = Key.new(:foo, FooType)
      key.set("something").should == 'to_mongo'
    end

    should "correctly typecast if object of that type is given" do
      key = Key.new(:foo, FooType)
      key.set(FooType.new('something')).should == 'to_mongo'
    end
  end

  context "getting a value with a custom type" do
    should "use #from_mongo to convert back to custom type" do
      key = Key.new(:foo, FooType)
      key.get('something').should == 'from_mongo'
    end
  end

  context "getting a value" do
    should "work with a type" do
      key = Key.new(:foo, String)
      key.get('bar').should == 'bar'
    end

    should "work without type" do
      key = Key.new(:foo)
      key.get([1, '2']).should == [1, '2']
      key.get(false).should == false
      key.get({}).should == {}
    end

    context "for a embedded_document" do
      should "default to nil" do
        key = Key.new(:foo, Address)
        key.get(nil).should be_nil
      end

      should "return instance if instance" do
        address = Address.new(:city => 'South Bend', :state => 'IN', :zip => 46544)
        key = Key.new(:foo, Address)
        key.get(address).should == address
      end
    end
  end

  context "getting a value with a default set" do
    setup do
      @key = Key.new(:foo, String, :default => 'baz')
    end

    should "return default value if value nil" do
      @key.get(nil).should == 'baz'
    end

    should "return a dup of the default value" do
      @key.get(nil).replace('bar')
      @key.get(nil).should == 'baz'
    end

    should "return value if not blank" do
      @key.get('foobar').should == 'foobar'
    end

    should "work with Boolean type and false value" do
      Key.new(:active, Boolean, :default => false).get(nil).should be_false
    end

    should "work with Boolean type and true value" do
      Key.new(:active, Boolean, :default => true).get(nil).should be_true
    end

    should "work with procs" do
       Key.new(:foo, String, :default => lambda { return 'hello world' }).get(nil).should == "hello world"
    end
  end
end # KeyTest
