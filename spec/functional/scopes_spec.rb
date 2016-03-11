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
          scope :ordered, lambda { |s| sort(s) }
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

  describe "with_scope" do
    describe "with a base query" do
      before do
        @klass = Doc do
        end
      end

      it "should scope" do
        u1 = @klass.create!(:first_name => "Scott")
        u2 = @klass.create!(:first_name => "Andrew")

        run = false

        @klass.with_scope(:first_name => "Scott") do
          run = true
          @klass.all.should == [u1]
        end

        run.should == true
      end

      it "should return the scope at the end of the block" do
        u1 = @klass.create!(:first_name => "Scott")
        u2 = @klass.create!(:first_name => "Andrew")

        run = false

        @klass.with_scope(:first_name => "Scott") do
          run = true
          @klass.all.should == [u1]
        end

        run.should == true

        @klass.all.should include(u1)
        @klass.all.should include(u2)
      end

      it "should be able to use an unscoped query" do
        u1 = @klass.create!(:first_name => "Scott")
        u2 = @klass.create!(:first_name => "Andrew")

        run = false

        @klass.with_scope(:first_name => "Scott") do
          @klass.unscoped do
            run = true
            @klass.all.should include(u1)
            @klass.all.should include(u2)
          end

          @klass.all.should == [u1]
        end

        run.should == true

        @klass.all.should include(u1)
        @klass.all.should include(u2)
      end

      it "should return the value of the block" do
        u1 = @klass.create!(:first_name => "Scott")
        u2 = @klass.create!(:first_name => "Andrew")

        result = @klass.with_scope(:first_name => "Scott") do
          @klass.all
        end

        result.should == [u1]
      end

      it "should have an empty list of default scope" do
        @klass.default_scopes.should == []
      end

      it "should apply the default scope to all queries" do
        @klass.key :active, Boolean, :default => true

        normal = @klass.create!
        inactive = @klass.create!(:active => false)

        @klass.default_scope do
          {
            :active => true
          }
        end

        @klass.all.should == [normal]
      end

      it "should allow multiple default scopes" do
        @klass.key :active, Boolean, :default => true
        @klass.key :soft_deleted, Boolean, :default => false

        normal = @klass.create!
        inactive = @klass.create!(:active => false)
        deleted = @klass.create!(:soft_deleted => true)

        @klass.default_scope do
          {
            :active => true,
          }
        end

        @klass.default_scope do
          {
            :soft_deleted => false
          }
        end

        @klass.all.should == [normal]
      end

      it "should allow a where inside a default_scope" do
        @klass.key :active, Boolean, :default => true

        normal = @klass.create!
        inactive = @klass.create!(:active => false)

        @klass.default_scope do
          where(:active => true)
        end

        @klass.all.should == [normal]
      end

      it "should allow a hash directly" do
        @klass.key :active, Boolean, :default => true

        normal = @klass.create!
        inactive = @klass.create!(:active => false)

        @klass.default_scope :active => true

        @klass.all.should == [normal]
      end

      it "should inherit default scopes, but only downwards" do
        @klass.default_scope do
          where(:active => true)
        end
        @subclass = Class.new(@klass)
        @subclass.default_scopes.length.should == 1

        @subclass.default_scope do
          {
            :foo => :bar
          }
        end

        @subclass.default_scopes.length.should == 2
        @klass.default_scopes.length.should == 1
      end
    end
  end

  describe "regression - multiple named scopes" do
    it "should merge the hashes from multiple scopes" do
      klass = Doc do
        key :a, Boolean
        key :b, Boolean
        key :c, Boolean

        scope :one, where(:a => true, :b => true)
        scope :two, where(:c => true)
      end

      obj = klass.create!(:a => false, :b => true, :c => true)
      klass.one.two.all.should == []

      obj2 = klass.create(:a => true, :b => true, :c => true)
      klass.one.two.all.should == [obj2]
    end
  end

  describe "regression - with multiple scopes that set a key to nil" do
    it "should still have the query as nil" do
      klass = Doc do
        key :a, Boolean

        scope :one, lambda {
          {
            :a => nil
          }
        }
        scope :two, lambda {
          {
            :a => nil
          }
        }
      end

      obj = klass.create!(:a => nil)
      klass.one.two.all.should == [obj]
    end
  end

  describe "regression - multiple scopes leading to empty query (array bug?)" do
    before do
      @klass = Doc do
        key :send_at, Time

        scope :unsent, lambda {
          now = Time.now

          {
            send_at: {
              '$lte' => now,
              '$gte' => now - 30.days,
            },
            sent_at: nil,
          }
        }

        scope :sorted, lambda {
          sort(send_at: 1)
        }
      end
    end

    it "should filter properly by dates" do
      old_obj = @klass.create(send_at: 3.months.ago)
      one_day_ago = @klass.create(send_at: 1.day.ago)
      two_days_ago = @klass.create(send_at: 2.days.ago)

      all_unsorted = @klass.unsent.all

      all_unsorted.should include(one_day_ago)
      all_unsorted.should include(two_days_ago)
      @klass.unsent.sorted.all.should == [two_days_ago, one_day_ago]
    end
  end
end
