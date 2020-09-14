require 'spec_helper'

describe "Indexing" do
  before do
    @document = Doc do
      key :first_name, String, :alias => :fn
      key :last_name, String
      key :age, Integer
      key :date, Date
    end
  end
  after { drop_indexes(@document) }

  context "against a known collection" do
    before do
      @document.stub(:collection).and_return(double(:name => :foo, :indexes => double()))
    end

    it "should delegate create_index to collection#create_one" do
      @document.collection.indexes.should_receive(:create_one).with({:arg => 1}, {})
      @document.create_index(:arg)
    end

    it "should delegate ensure_index to collection#create_one" do
      @document.collection.indexes.should_receive(:create_one).with({:arg => 1}, {})
      @document.create_index(:arg)
    end
    it "should delegate drop_index to collection" do
      @document.collection.indexes.should_receive(:drop_one).with(:arg)
      @document.drop_index(:arg)
    end

    it "should delegate drop_indexes to collection" do
      @document.collection.indexes.should_receive(:drop_all)
      @document.drop_indexes
    end
  end

  it "should allow creating index for an aliased key" do
    @document.ensure_index :first_name
    @document.should have_index('fn_1')
  end

  it "should allow creating index for an aliased key without using the alias" do
    @document.ensure_index :fn
    @document.should have_index('fn_1')
  end

  it "should allow creating index for an unaliased key" do
    @document.ensure_index :last_name
    @document.should have_index('last_name_1')
  end

  it "should allow specifying as a hash" do
    @document.ensure_index({last_name: -1})
    @document.should have_index('last_name_-1')
  end

  it "should allow creating unique index for a key" do
    @document.ensure_index :first_name, :unique => true
    @document.should have_index('fn_1')
  end

  it "should allow creating index on multiple keys" do
    @document.ensure_index [[:first_name, 1], [:last_name, -1]]
    @document.should have_index('fn_1_last_name_-1')
  end

  it "should work with :index shortcut when defining key" do
    suppress_stderr { @document.key :father, String, :index => true }
    @document.should have_index('father_1')
  end
end
