require 'test_helper'

class TestRailsCompatibility < Test::Unit::TestCase
  class Item
    include MongoMapper::EmbeddedDocument
    key :for_all, String
  end

  class FirstItem < Item  
    key :first_only, String
    many :second_items
  end

  class SecondItem < Item
    key :second_only, String
  end
  
  context "EmbeddedDocument" do    
    should "alias many to has_many" do
      FirstItem.should respond_to(:has_many)
      FirstItem.method(:has_many).should == FirstItem.method(:many)
    end
    
    should "have column names" do
      Item.column_names.sort.should == ['_id', 'for_all']
      FirstItem.column_names.sort.should == ['_id', 'first_only', 'for_all']
      SecondItem.column_names.sort.should == ['_id', 'for_all', 'second_only']
    end
    
    should "alias new to new_record?" do
      instance = Item.new
      instance.new_record?.should == instance.new?
    end
  end
end