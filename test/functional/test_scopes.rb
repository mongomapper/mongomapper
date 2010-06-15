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

    context "chaining" do
      setup do
        @document.class_eval do
          scope :by_age,  lambda { |age| {:age => age} }
          scope :by_name, lambda { |name| {:name => name} }
        end
      end

      should "work with scope methods" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 60)
        @document.create(:name => 'Bill', :age => 50)
        docs = @document.by_age(60).by_name('John').all
        docs.size.should == 1
        docs.first.name.should == 'John'
      end

      should "work on query methods" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'John', :age => 50)
        @document.create(:name => 'Bill', :age => 50)
        docs = @document.where(:name => 'John').by_age(50).all
        docs.size.should == 1
        docs.first.age.should == 50
      end

      context "with model methods" do
        should "work if method on model returns a query" do
          @document.create(:name => 'John', :age => 10)
          @document.create(:name => 'John', :age => 20)
          @document.class_eval do
            def self.young
              query(:age.lte => 12)
            end
          end
          docs = @document.by_name('John').young.all
          docs.size.should == 1
          docs.first.age.should == 10
        end

        should "not work if method on model, but return not a query" do
          @document.class_eval { def self.age; 20 end }
          lambda { @document.by_name('John').age }.should raise_error(NoMethodError)
        end
      end
    end
  end
end