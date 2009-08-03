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
    should "raise error for to_param as embedded do not have id's" do
      lambda { Item.new.to_param }.should raise_error
    end
    
    should "alias many to has_many" do
      FirstItem.should respond_to(:has_many)
      FirstItem.method(:has_many).should == FirstItem.method(:many)
    end
    
    should "have column names" do
      Item.column_names.sort.should == ['_id', 'for_all']
      FirstItem.column_names.sort.should == ['_id', 'first_only', 'for_all']
      SecondItem.column_names.sort.should == ['_id', 'for_all', 'second_only']
    end
  end
end