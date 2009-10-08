require 'test_helper'

class LoggerTest < Test::Unit::TestCase
  context "with connection that has logger" do
    setup do
      @output = StringIO.new
      @logger = Logger.new(@output)
      MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => @logger)
    end

    should "be able to get access to that logger" do
      MongoMapper.logger.should == @logger
    end
    
    should "be able to log messages" do
      MongoMapper.logger.debug 'testing'
      @output.string.include?('testing').should be_true
    end
  end
end