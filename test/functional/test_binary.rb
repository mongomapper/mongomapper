require 'test_helper'

class BinaryTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end
  
  should "serialize and deserialize correctly" do
    klass = Class.new do
      include MongoMapper::Document
      set_collection_name 'test'
      key :contents, Binary
    end
    
    doc = klass.new(:contents => '010101')
    doc.save
    
    doc = klass.find(doc.id)
    doc.contents.to_s.should == ByteBuffer.new('010101').to_s
  end
end