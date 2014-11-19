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
      allow(@document).to receive(:collection).and_return(double(:name => :foo))
    end
    [:create_index, :ensure_index].each do |method|
      it "should delegate #{method} to collection" do
        expect(@document.collection).to receive(method).with(:arg, {})
        @document.send(method, :arg)
      end
    end

    it "should delegate drop_index to collection" do
      expect(@document.collection).to receive(:drop_index).with(:arg)
      @document.drop_index(:arg)
    end

    it "should delegate drop_indexes to collection" do
      expect(@document.collection).to receive(:drop_indexes)
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

  it "should allow creating unique index for a key" do
    @document.ensure_index :first_name, :unique => true
    @document.should have_index('fn_1')
  end

  it "should allow creating index on multiple keys" do
    @document.ensure_index [[:first_name, 1], [:last_name, -1]]

    # order is different for different versions of ruby so instead of
    # just checking have_index('first_name_1_last_name_-1') I'm checking
    # the values of the indexes to make sure the index creation was successful
    @document.collection.index_information.detect do |index|
      keys = index[0]
      keys.include?('fn_1') && keys.include?('last_name_-1')
    end.should_not be_nil
  end

  it "should work with :index shortcut when defining key" do
    silence_stderr { @document.key :father, String, :index => true }
    @document.should have_index('father_1')
  end
end