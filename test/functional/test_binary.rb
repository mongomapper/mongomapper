require 'test_helper'

class BinaryTest < Test::Unit::TestCase  
  should "serialize and deserialize correctly" do
    klass = Class.new do
      include MongoMapper::Document
      set_collection_name 'test'
      key :contents, Binary
    end
    klass.collection.remove
    
    doc = klass.new(:contents => '010101')
    doc.save
    
    doc = doc.reload
    doc.contents.to_s.should == ByteBuffer.new('010101').to_s
  end
  
  context "Saving a document with a blank binary value" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        set_collection_name 'test'
        key :file, Binary
      end
      @document.collection.remove
    end

    should "not fail" do
      assert_nothing_raised { @document.new(:file => nil).save }
    end
  end
end