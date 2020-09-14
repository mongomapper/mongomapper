require 'spec_helper'
require 'active_support/cache/memory_store'

describe "Documents with the Dumpable plugin" do
  let(:doc) { Doc { key :foo, String } }
  let(:answer) { Answer.create(:body => "answer body") }
  let(:store)  { ActiveSupport::Cache::MemoryStore.new(:size => 1.megabyte) }

  it "should be able to be marshalled" do
    lambda { Marshal.dump(answer) }.should_not raise_error
  end

  it "should be able to be unmarshalled" do
    dumped = Marshal.dump(answer)
    reconstituted_answer = Marshal.load(dumped)
    reconstituted_answer.attributes.should == answer.attributes
  end

  it "should be able to be saved in a Rails cache" do
    fetched = store.fetch("foo") { Answer.find(answer._id) }
    fetched.body.should == "answer body"
    fetched._id.should == answer._id
  end
end