require "spec_helper"

describe "GlobalID" do
  before do
    @document = stub_const("TestDocument", Doc("TestDocument") do
      key :name, String
    end)
  end

  it "generates a valid GlobalID" do
    doc = @document.create!(name: "Test")
    doc.to_global_id.should be_a(GlobalID)
  end

  it "can be found by GlobalID" do
    doc = @document.create!(name: "Test")
    global_id = doc.to_global_id
    found_doc = GlobalID::Locator.locate(global_id)
    found_doc.should == doc
  end
end
