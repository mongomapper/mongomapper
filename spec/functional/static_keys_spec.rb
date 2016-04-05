require 'spec_helper'

describe MongoMapper::Plugins::Keys::Static do
  before do
    @klass = Class.new do
      include MongoMapper::Document
    end
  end

  it "is off by default" do
    @klass.static_keys.should == false
  end

  it "can be turned on" do
    @klass.static_keys = true
    @klass.static_keys.should == true
  end

  describe "a class with static keys" do
    before do
      @klass = Class.new do
        include MongoMapper::Document

        self.static_keys = true

        attr_accessor :an_accessor

        key "valid_key", String
      end

      @obj = @klass.new
    end

    it "should be able to assign to a valid key" do
      @obj.valid_key = "foo"
      @obj.valid_key.should == "foo"
    end

    it "should raise a MissingKeyError if trying to assign to a field that does not exist" do
      lambda {
        @obj['foo'] = "foo"
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end

    it "should raise a MissingKeyError if trying to read from a field that does not exist" do
      lambda {
        @obj['foo']
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end

    it "should raise a MissingKeyError if trying to set attributes= to a field that does not exist" do
      lambda {
        @obj.attributes = {:foo => "foo"}
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end

    it "should be able to call a method" do
      @obj.an_accessor = :bar
      @obj.an_accessor.should == :bar
    end

    it "should raise a NoMethodError if trying to call the non-existant key method" do
      lambda {
        @obj.foo
      }.should raise_error(NoMethodError)
    end

    it "should raise for read_key" do
      lambda {
        @obj.read_key('foo')
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end

    it "should raise for attribute" do
      lambda {
        @obj.attribute('foo')
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end

    it "should not raise if trying to assign to a field that exists (but with a symbol instead of a string)" do
      lambda {
        @obj.write_key(:valid_key, "foo")
      }.should_not raise_error

      @obj.valid_key.should == "foo"
    end

    it "should not raise a MissingKeyError if trying to read from a field that exists (but with a symbol instead of a string)" do
      lambda {
        @obj[:valid_key]
      }.should_not raise_error
    end

    it "should not blow up when loading if there is a key defined in the db that has not been defined (but it should not load it)" do
      @klass.collection.insert_one({ :foo => "bar", :valid_key => "something" })
      @obj = @klass.first
      @obj.valid_key.should == "something"

      lambda {
        @obj.foo
      }.should raise_error(NoMethodError)
    end
  end

  describe "a class without static keys" do
    before do
      @klass = Class.new do
        include MongoMapper::Document
        key :valid_key, String
      end

      @obj = @klass.new
    end

    it "should be able to assign to a valid key" do
      @obj.valid_key = "foo"
      @obj.valid_key.should == "foo"
    end

    it "should be able to read and assign a dynamic key" do
      @obj['foo'].should be_nil
      @obj['foo'] = "bar"
      @obj['foo'].should == "bar"
    end
  end

  describe "with mixed static + non static models" do
    before do
      @static_model = Class.new do
        include MongoMapper::Document
        self.static_keys = true
      end

      @non_static_model = Class.new do
        include MongoMapper::Document
        self.static_keys = false
      end

      @static_key_object = @static_model.new
      @non_static_key_object = @non_static_model.new
    end

    it "should allow non-static key assignment to one, only static assignment to the other" do
      @non_static_key_object['foo'] = 'bar'
      @non_static_key_object.foo.should == 'bar'
      @non_static_key_object['foo'].should == 'bar'

      lambda {
        @static_key_object['foo'] = 'bar'
      }.should raise_error(MongoMapper::Plugins::Keys::Static::MissingKeyError)
    end
  end
end