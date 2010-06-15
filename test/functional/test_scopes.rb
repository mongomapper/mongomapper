require 'test_helper'

class ScopesTest < Test::Unit::TestCase
  context "Scopes" do
    setup do
      @document = Doc() do
        key :name, String
        key :age, Integer
        timestamps!
      end
    end

    context "basic scopes" do
      setup do
        @document.class_eval do
          scope :old, :age.gt => 60
          scope :teens, :age.gte => 13, :age.lte => 19
        end
      end

      should "know what scopes have been added" do
        @document.scopes.size.should == 2
        @document.scopes.keys.map(&:to_s).sort.should == %w(old teens)
      end

      should "return a plucky query" do
        @document.old.should be_instance_of(Plucky::Query)
      end

      should "work" do
        @document.create(:name => 'John', :age => 99)
        @document.create(:name => 'Frank', :age => 15)
        docs = @document.old.all
        docs.size.should == 1
        docs[0].name.should == 'John'
      end
    end
    
    context "dynamic scopes" do
      setup do
        @document.class_eval do
          scope :age,  lambda { |age| {:age => age} }
          scope :ages, lambda { |low, high| {:age.gte => low, :age.lte => high} }
        end
      end

      should "work with single argument" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 50)
        docs = @document.age(60).all
        docs.size.should == 1
        docs.first.name.should == 'John'
      end
      
      should "work with multiple arguments" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 50)
        @document.create(:name => 'Bill', :age => 40)
        docs = @document.ages(50, 70).all
        docs.size.should == 2
        docs.map(&:name).sort.should == %w(Frank John)
      end
    end
  end
end