require 'test_helper'

class DynamicFinderTest < Test::Unit::TestCase
  DynamicFinder = MongoMapper::Plugins::DynamicQuerying::DynamicFinder

  should "initialize with method" do
    finder = DynamicFinder.new(:foobar)
    finder.method.should == :foobar
  end

  context "found?" do
    should "be true for find_by" do
      DynamicFinder.new(:find_by_foo).found?.should be_true
    end

    should "be true for find_by with !" do
      DynamicFinder.new(:find_by_foo!).found?.should be_true
    end

    should "be true for find_all_by" do
      DynamicFinder.new(:find_all_by_foo).found?.should be_true
    end

    should "be true for find_or_initialize_by" do
      DynamicFinder.new(:find_or_initialize_by_foo).found?.should be_true
    end

    should "be true for find_or_create_by" do
      DynamicFinder.new(:find_or_create_by_foo).found?.should be_true
    end

    should "be false for anything else" do
      [:foobar, :bazwick].each do |method|
        DynamicFinder.new(method).found?.should be_false
      end
    end
  end

  context "find_all_by" do
    should "parse one attribute" do
      DynamicFinder.new(:find_all_by_foo).attributes.should == %w(foo)
    end

    should "parse multiple attributes" do
      DynamicFinder.new(:find_all_by_foo_and_bar).attributes.should == %w(foo bar)
      DynamicFinder.new(:find_all_by_foo_and_bar_and_baz).attributes.should == %w(foo bar baz)
    end

    should "set finder to :all" do
      DynamicFinder.new(:find_all_by_foo_and_bar).finder.should == :all
    end
  end

  context "find_by" do
    should "parse one attribute" do
      DynamicFinder.new(:find_by_foo).attributes.should == %w(foo)
    end

    should "parse multiple attributes" do
      DynamicFinder.new(:find_by_foo_and_bar).attributes.should == %w(foo bar)
    end

    should "set finder to :first" do
      DynamicFinder.new(:find_by_foo).finder.should == :first
    end

    should "set bang to false" do
      DynamicFinder.new(:find_by_foo).bang.should be_false
    end
  end

  context "find_by with !" do
    should "parse one attribute" do
      DynamicFinder.new(:find_by_foo!).attributes.should == %w(foo)
    end

    should "parse multiple attributes" do
      DynamicFinder.new(:find_by_foo_and_bar!).attributes.should == %w(foo bar)
    end

    should "set finder to :first" do
      DynamicFinder.new(:find_by_foo!).finder.should == :first
    end

    should "set bang to true" do
      DynamicFinder.new(:find_by_foo!).bang.should be_true
    end
  end

  context "find_or_initialize_by" do
    should "parse one attribute" do
      DynamicFinder.new(:find_or_initialize_by_foo).attributes.should == %w(foo)
    end

    should "parse multiple attributes" do
      DynamicFinder.new(:find_or_initialize_by_foo_and_bar).attributes.should == %w(foo bar)
    end

    should "set finder to :first" do
      DynamicFinder.new(:find_or_initialize_by_foo).finder.should == :first
    end

    should "set instantiator to new" do
      DynamicFinder.new(:find_or_initialize_by_foo).instantiator.should == :new
    end
  end

  context "find_or_create_by" do
    should "parse one attribute" do
      DynamicFinder.new(:find_or_create_by_foo).attributes.should == %w(foo)
    end

    should "parse multiple attributes" do
      DynamicFinder.new(:find_or_create_by_foo_and_bar).attributes.should == %w(foo bar)
    end

    should "set finder to :first" do
      DynamicFinder.new(:find_or_create_by_foo).finder.should == :first
    end

    should "set instantiator to new" do
      DynamicFinder.new(:find_or_create_by_foo).instantiator.should == :create
    end
  end
end