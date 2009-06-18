require 'test_helper'

class TestRailsCompatibility < Test::Unit::TestCase
  def setup
    @document = Class.new do
      include MongoMapper::Document
    end
  end
  
  should "have to_param that returns id" do
    instance = @document.create('_id' => '1234')
    instance.to_param.should == '1234'
  end
  
  should "alias new to new_record?" do
    instance = @document.new
    instance.new_record?.should == instance.new?
  end
  
  should "have column names" do
    @document.key :fname, String
    @document.column_names.sort.should == ['_id', 'created_at', 'fname', 'updated_at']
  end
end