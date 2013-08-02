require 'spec_helper'

describe "Scopes" do
  context "Scopes" do
    before do
      @document = Doc() do
        key :name, String
        key :age, Integer
        timestamps!
      end
    end

    context "basic scopes" do
      before do
        @document.class_eval do
          scope :old, :age.gt => 60
          scope :teens, :age.gte => 13, :age.lte => 19
        end
      end

      it "should know what scopes have been added" do
        @document.scopes.size.should == 2
        @document.scopes.keys.map(&:to_s).sort.should == %w(old teens)
      end

      it "should return a plucky query" do
        @document.old.should be_kind_of(Plucky::Query)
      end

      it "should work" do
        @document.create(:name => 'John', :age => 99)
        @document.create(:name => 'Frank', :age => 15)
        docs = @document.old.all
        docs.size.should == 1
        docs[0].name.should == 'John'
      end

      # Regression test for #534
      context "when where() is invoked via a scope before a key is defined" do
        let(:given_id) { BSON::ObjectId.new }
        let(:doc) { Doc {
           key :type, String

           # Ordering is important here; where needs to happen before foo_id is defined
           # in order to produce the behavior we're testing against regression.
           scope :type, where(:type => "bar")
           key :foo_id, ObjectId
        }}
        before {
          doc.collection.drop
          doc.create({:foo_id => given_id})
        }

        it "should work without typecasts" do
          doc.where(:foo_id => given_id).count.should == 1
        end

        it "should work with typecasts" do
          doc.where(:foo_id => given_id.to_s).count.should == 1
        end
      end
    end

    context "dynamic scopes" do
      before do
        @document.class_eval do
          scope :age,     lambda { |age| {:age => age} }
          scope :ages,    lambda { |low, high| {:age.gte => low, :age.lte => high} }
          scope :ordered, lambda { |sort| sort(sort) }
        end
      end

      it "should work with single argument" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 50)
        docs = @document.age(60).all
        docs.size.should == 1
        docs.first.name.should == 'John'
      end

      it "should work with multiple arguments" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 50)
        @document.create(:name => 'Bill', :age => 40)
        docs = @document.ages(50, 70).all
        docs.size.should == 2
        docs.map(&:name).sort.should == %w(Frank John)
      end

      it "should work with queries" do
        john  = @document.create(:name => 'John', :age => 60)
        frank = @document.create(:name => 'Frank', :age => 50)
        bill  = @document.create(:name => 'Bill', :age => 40)
        @document.ordered(:age).all.should == [bill, frank, john]
      end
    end

    context "query scopes" do
      before do
        @document.class_eval do
          scope :boomers, where(:age.gte => 60).sort(:age)
        end
      end

      it "should work" do
        todd = @document.create(:name => 'Todd', :age => 65)
        john = @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 50)
        @document.create(:name => 'Bill', :age => 40)
        docs = @document.boomers.all
        docs[0].should == john
        docs[1].should == todd
      end
    end

    context "chaining" do
      before do
        @document.class_eval do
          scope :by_age,  lambda { |age| {:age => age} }
          scope :by_name, lambda { |name| {:name => name} }
        end
      end

      it "should work with scope methods" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'Frank', :age => 60)
        @document.create(:name => 'Bill', :age => 50)
        docs = @document.by_age(60).by_name('John').all
        docs.size.should == 1
        docs.first.name.should == 'John'
      end

      it "should work on query methods" do
        @document.create(:name => 'John', :age => 60)
        @document.create(:name => 'John', :age => 50)
        @document.create(:name => 'Bill', :age => 50)
        docs = @document.where(:name => 'John').by_age(50).all
        docs.size.should == 1
        docs.first.age.should == 50
      end

      context "with model methods" do
        it "should work if method returns a query" do
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

        it "should not work if method does not return a query" do
          @document.class_eval { def self.age; 20 end }
          @document.by_name('John').age.should == 20
        end
      end
    end

    context "with single collection inheritance" do
      before do
        class ::Item
          include MongoMapper::Document
          scope :by_title,  lambda { |title| {:title => title} }
          scope :published, lambda { {:published_at.lte => Time.now.utc} }

          key   :title, String
          key   :published_at, Time
        end
        Item.collection.remove

        class ::Page < ::Item; end
        class ::Blog < ::Item
          key :slug, String
          scope :by_slug, lambda { |slug| {:slug => slug} }
        end
      end

      after do
        Object.send :remove_const, 'Item' if defined?(::Item)
        Object.send :remove_const, 'Page' if defined?(::Page)
        Object.send :remove_const, 'Blog' if defined?(::Blog)
      end

      it "should inherit scopes" do
        Page.scopes.keys.map(&:to_s).sort.should == %w(by_title published)
      end

      it "should work with _type" do
        item = Item.create(:title => 'Home')
        page = Page.create(:title => 'Home')
        Page.by_title('Home').first.should == page
      end

      it "should limit subclass scopes to subclasses" do
        Item.scopes.keys.map(&:to_s).should =~ %w(by_title published)
        Blog.scopes.keys.map(&:to_s).should =~ %w(by_slug by_title published)
      end
    end
  end
end
