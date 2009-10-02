require 'test_helper'

class BinaryTest < Test::Unit::TestCase
  context "to_mongo" do
    should "create new byte buffer so mongo knows how to serialize" do
      Binary.to_mongo('asdfsadasdfs').is_a?(ByteBuffer).should be_true
    end
  end
  
  context "from_mongo" do
    should "return value" do
      Binary.from_mongo(ByteBuffer.new('asdfasdfasdf')).to_s.should == ByteBuffer.new('asdfasdfasdf').to_s
    end
  end
end