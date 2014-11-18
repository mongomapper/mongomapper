require 'spec_helper'

describe "Logger" do
  context "with connection that has logger" do
    before do
      @output = StringIO.new
      @logger = Logger.new(@output)
      MongoMapper.connection = Mongo::MongoClient.new('127.0.0.1', 27017, :logger => @logger)
    end

    it "should be able to get access to that logger" do
      MongoMapper.logger.should == @logger
    end

    it "should be able to log messages" do
      MongoMapper.logger.debug 'testing'
      @output.string.include?('testing').should be_truthy
    end
  end
end