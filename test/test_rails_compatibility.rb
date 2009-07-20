require 'test_helper'

class Item
  include MongoMapper::EmbeddedDocument
  key :for_all, String
end

class FirstItem < Item  
  key :first_only, String
end

class SecondItem < Item
  key :second_only, String
end

class Order
  include MongoMapper::Document
  many :items, :polymorphic => true, :class_name => "Item"
  key :order_only, String
end

class TestRailsCompatibility < Test::Unit::TestCase
  def setup
    @document = Class.new do
      include MongoMapper::Document
    end
  end
  
  context "EmbeddedDocument" do
    should "have to_param that returns id" do
      first_item = FirstItem.new
      second_item = SecondItem.new

      order = Order.create('_id' => '1234')
      order.items = [
        first_item,
        second_item
      ]
      order.to_param.should == '1234'

      lambda { first_item.to_param }.should raise_error
      lambda { second_item.to_param }.should raise_error
    end

    should "have column names" do
      Order.column_names.sort.should == ['_id', 'created_at', 'order_only', 'updated_at']
      FirstItem.column_names.sort.should == ['first_only', 'for_all']
      SecondItem.column_names.sort.should == ['for_all', 'second_only']
    end
  end

  context "Document" do
    should "have to_param that returns id" do
      instance = @document.create('_id' => '1234')
      instance.to_param.should == '1234'
    end

    should "alias new to new_record?" do
      instance = @document.new
      instance.new_record?.should == instance.new?
    end

    should "alias many to has_many" do
      @document.should respond_to(:has_many)
      @document.method(:has_many).should == @document.method(:many)
    end

    should "have column names" do
      @document.key :fname, String
      @document.column_names.sort.should == ['_id', 'created_at', 'fname', 'updated_at']
    end
  end
end