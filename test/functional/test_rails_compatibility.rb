require 'test_helper'

class TestRailsCompatibility < Test::Unit::TestCase
  class Item
    include MongoMapper::EmbeddedDocument
    key :for_all, String
  end
  
  class Order
    include MongoMapper::Document
    many :items, :class_name => 'TestRailsCompatibility::Item'
    key :order_only, String
  end
  
  context "Document" do
    setup do
      Order.collection.clear
    end
  
    should "have to_param that returns id" do
      instance = Order.create('_id' => 1234)
      instance.to_param.should == '1234'
    end

    should "alias new to new_record?" do
      instance = Order.new
      instance.new_record?.should == instance.new?
    end
  end
end