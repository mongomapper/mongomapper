require 'spec_helper'
require 'support/models'

describe "Document" do
  before do
    @document = Doc do
      key :first_name, String
      key :last_name, String
      key :age, Integer
      key :date, Date
    end
  end

  context "array key" do
    before do
      @document.key :tags, Array
    end

    it "should give correct default" do
      doc = @document.new
      doc.tags.should == []
    end

    it "should work with assignment" do
      doc = @document.new
      doc.tags = %w(foo bar)
      doc.tags.should == %w(foo bar)
    end

    it "should work with assignment after saving" do
      doc = @document.new
      doc.tags = %w(foo bar)
      doc.save
      doc.tags.should == %w(foo bar)
      doc.reload.tags.should == %w(foo bar)
    end

    it "should work with assignment then <<" do
      doc = @document.new
      doc.tags = []
      doc.tags << "foo"
      doc.tags.should == ["foo"]
    end

    it "should work with <<" do
      doc = @document.new
      doc.tags << "foo"
      doc.tags.should == ["foo"]
    end

    it "should work with << then save" do
      doc = @document.new
      doc.tags << "foo"
      doc.tags << "bar"
      doc.save
      doc.tags.should == %w(foo bar)
      doc.reload.tags.should == %w(foo bar)
    end
  end

  context "hash key" do
    before do
      @document.key :foo, Hash
    end

    it "should give correct default" do
      doc = @document.new
      doc.foo.should == {}
    end

    it "should work with []=" do
      doc = @document.new
      doc.foo["quux"] = "bar"
      doc.foo["quux"].should == "bar"
      doc.foo.should == { "quux" => "bar" }
    end

    it "should work with indifferent access" do
      doc = @document.new
      doc.foo = {:baz => 'bar'}
      doc.foo[:baz].should == 'bar'
      doc.foo['baz'].should == 'bar'
    end

    it "should work with indifferent access after save" do
      doc = @document.new
      doc.foo = {:baz => 'bar'}
      doc.save

      doc = doc.reload
      doc.foo[:baz].should == 'bar'
      doc.foo['baz'].should == 'bar'
    end
  end

  context "custom type key with default" do
    before do
      @document.key :window, WindowSize, :default => WindowSize.new(600, 480)
    end

    it "should default to default" do
      doc = @document.new
      doc.window.should == WindowSize.new(600, 480)

    end

    it "should save and load from mongo" do
      doc = @document.new
      doc.save

      doc = doc.reload
      doc.window.should == WindowSize.new(600, 480)
    end
  end

  context "key with proc default value" do
    before do
      @document.key :proc_default, String, :default => lambda { return 'string' }
    end

    it "should detect and run proc default" do
      doc = @document.new
      doc.proc_default.should == 'string'
    end

    it "should save and load from mongo" do
      doc = @document.create
      doc = doc.reload
      doc.proc_default.should == 'string'
    end
  end

  context "symbol key" do
    before do
      @document.key :foo, Symbol, :default => lambda { 123 }
    end

    it "should return default value" do
      doc = @document.new
      doc.foo.should == :'123'
    end

    it "should return symbol value" do
      doc = @document.create :foo => 'qwerty'
      doc.foo.should == :qwerty

      doc.set :foo => 'poiuyt'
      doc.reload
      doc.foo.should == :poiuyt

      doc.foo = 'asdf'
      doc.foo.should == :asdf
    end

    it "should return typecasted value" do
      doc = @document.new
      (doc.foo = 'qwerty').should == 'qwerty'
    end
  end

  it "should have instance method for collection" do
    @document.new.collection.name.should == @document.collection.name
  end

  it "should have instance method for database" do
    @document.new.database.should == @document.database
  end

  context "#destroyed?" do
    before do
      @doc1 = @document.create(:first_name => 'John', :last_name => 'Nunemaker', :age => '27')
    end

    it "should be true if deleted" do
      @doc1.delete
      @doc1.should be_destroyed
    end

    it "should be true if destroyed" do
      @doc1.destroy
      @doc1.should be_destroyed
    end

    it "should be false if not deleted or destroyed" do
      @doc1.should_not be_destroyed
    end
  end

  context "#persisted?" do
    before do
      @doc = @document.new(:first_name => 'John', :last_name => 'Nunemaker', :age => '27')
    end

    it "should be false if new" do
      @doc.should_not be_persisted
    end

    it "should be false if destroyed" do
      @doc.save
      @doc.destroy
      @doc.should be_destroyed
      @doc.should_not be_persisted
    end

    it "should be true if not new or destroyed" do
      @doc.save
      @doc.should be_persisted
    end
  end

  context "#reload" do
    before do
      @foo_class = Doc do
        key :name
      end

      @bar_class = EDoc do
        key :name
      end

      @document.many :foos, :class => @foo_class
      @document.many :bars, :class => @bar_class
      @document.belongs_to :foo, :class => @foo_class
      @document.one :bar, :class => @bar_class

      @instance = @document.create({
        :age  => 39,
        :foos => [@foo_class.new(:name => '1')],
        :bars => [@bar_class.new(:name => '1')],
        :foo  => @foo_class.new(:name => '2'),
        :bar  => @bar_class.new(:name => '2')
      })
    end

    it "should reload keys from the database" do
      @instance.age = 37
      @instance.age.should == 37
      @instance.reload
      @instance.age.should == 39
    end

    it "should reset many associations" do
      expect(@instance.foos).to receive(:reset).at_least(1).times
      expect(@instance.bars).to receive(:reset).at_least(1).times
      @instance.reload
    end

    it "should reset belongs_to association" do
      @instance.foo = nil
      @instance.reload
      @instance.foo.should_not be_nil
    end

    it "should reset one association" do
      @instance.bar = nil
      @instance.reload
      @instance.bar.should_not be_nil
    end

    it "should reset nil one association" do
    end

    it "should reinstantiate embedded associations" do
      @instance.reload
      @instance.bars.first.name.should == '1'
    end

    it "should return self" do
      @instance.reload.object_id.should == @instance.object_id
    end

    it "should raise DocumentNotFound if not found" do
      @instance.destroy
      expect { @instance.reload }.to raise_error(MongoMapper::DocumentNotFound)
    end

    it "should clear keys that were removed from the database" do
      @instance.unset(:age)
      @instance.reload.age.should be_nil
    end
  end

  context "database has keys not defined in model" do
    before do
      @id = BSON::ObjectId.new
      @document.collection.insert({
        :_id            => @id,
        :first_name     => 'John',
        :last_name      => 'Nunemaker',
        :age            => 27,
        :favorite_color => 'red',
        :skills         => ['ruby', 'rails', 'javascript', 'xhtml', 'css']
      })
    end

    it "should assign all keys from database" do
      doc = @document.find(@id)
      doc.first_name.should == 'John'
      doc.last_name.should == 'Nunemaker'
      doc.age.should == 27
      doc.favorite_color.should == 'red'
      doc.skills.should == ['ruby', 'rails', 'javascript', 'xhtml', 'css']
    end
  end

  it "should not walk ObjectSpace when creating a model" do
    expect(ObjectSpace).to receive(:each_object).never
    Doc()
  end
end
