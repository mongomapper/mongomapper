require 'spec_helper'

describe MongoMapper::Plugins::Logger do
  context 'an instance' do
    it "should have access to logger" do
      doc = document.new
      doc.logger.should == document.logger
      doc.logger.should be_instance_of(Logger)
    end
  end
end
