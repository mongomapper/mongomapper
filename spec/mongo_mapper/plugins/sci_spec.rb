require 'spec_helper'

describe MongoMapper::Plugins::Sci do
  context "descendants" do
    it "should default to an empty array" do
      Enter.descendants.should == []
    end

    it "should be recorded" do
      Message.descendants.should == [Enter, Exit, Chat]
    end
  end
end
