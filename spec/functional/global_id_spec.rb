require "spec_helper"

describe "GlobalID" do

  class TestDocument
    include MongoMapper::Document

    key :name, String
  end

  it "generates a valid GlobalID" do
    doc = TestDocument.create!(name: "Test")
    doc.to_global_id.should be_a(GlobalID)
  end

  it "can be found by GlobalID" do
    doc = TestDocument.create!(name: "Test")
    global_id = doc.to_global_id
    found_doc = GlobalID::Locator.locate(global_id)
    found_doc.should == doc
  end
end