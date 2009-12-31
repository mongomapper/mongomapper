require 'test_helper'

class ModifierTest < Test::Unit::TestCase
  def setup
    @page_class = Class.new do
      include MongoMapper::Document
      def self.name; 'Page' end
      
      key :title, String
      key :day_count, Integer, :default => 0
      key :week_count, Integer, :default => 0
      key :month_count, Integer, :default => 0
    end
    @page_class.collection.remove
  end
  
  def assert_page_counts(page, day_count, week_count, month_count)
    page.reload
    page.day_count.should == day_count
    page.week_count.should == week_count
    page.month_count.should == month_count
  end
  
  should "be able to increment with criteria and modifier hashes" do
    page = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.increment({:title => 'Home'}, {
      :day_count => 1, :week_count => 2, :month_count => 3
    })
    
    assert_page_counts page, 1, 2, 3
    assert_page_counts page2, 1, 2, 3
  end
  
  should "be able to increment with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.increment(page.id, page2.id, {
      :day_count => 1, :week_count => 2, :month_count => 3
    })
    
    assert_page_counts page, 1, 2, 3
    assert_page_counts page2, 1, 2, 3
  end
  
  should "be able to decrement with criteria and modifier hashes" do
    page = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    page2 = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    
    @page_class.decrement({:title => 'Home'}, {
      :day_count => 1, :week_count => 2, :month_count => 3
    })
    
    assert_page_counts page, 0, 0, 0
    assert_page_counts page2, 0, 0, 0
  end
  
  should "be able to decrement with ids and modifier hash" do
    page = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    page2 = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    
    @page_class.decrement(page.id, page2.id, {
      :day_count => 1, :week_count => 2, :month_count => 3
    })
    
    assert_page_counts page, 0, 0, 0
    assert_page_counts page2, 0, 0, 0
  end
  
  should "always decrement when decrement is called whether number is positive or negative" do
    page = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    page2 = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
    
    @page_class.decrement(page.id, page2.id, {
      :day_count => -1, :week_count => 2, :month_count => -3
    })
    
    assert_page_counts page, 0, 0, 0
    assert_page_counts page2, 0, 0, 0
  end
end