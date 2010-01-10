require 'test_helper'

class ModifierTest < Test::Unit::TestCase
  def setup
    @page_class = Doc do
      key :title, String
      key :day_count, Integer, :default => 0
      key :week_count, Integer, :default => 0
      key :month_count, Integer, :default => 0
      key :tags, Array
    end
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
  
  should "be able to set with criteria and modifier hashes" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.set({:title => 'Home'}, :title => 'Home Revised')
    
    page.reload
    page.title.should == 'Home Revised'
    
    page2.reload
    page2.title.should == 'Home Revised'
  end
  
  should "be able to set with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.set(page.id, page2.id, :title => 'Home Revised')
    
    page.reload
    page.title.should == 'Home Revised'
    
    page2.reload
    page2.title.should == 'Home Revised'
  end
  
  should "be able to push with criteria and modifier hashes" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.push({:title => 'Home'}, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(foo)
    
    page2.reload
    page.tags.should == %w(foo)
  end
  
  should "be able to push with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.push(page.id, page2.id, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(foo)
    
    page2.reload
    page.tags.should == %w(foo)
  end

  should "be able to push all with criteria and modifier hashes" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    tags = %w(foo bar)
    
    @page_class.push_all({:title => 'Home'}, :tags => tags)
    
    page.reload
    page.tags.should == tags
    
    page2.reload
    page.tags.should == tags
  end
  
  should "be able to push all with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home')
    page2 = @page_class.create(:title => 'Home')
    tags = %w(foo bar)
    
    @page_class.push_all(page.id, page2.id, :tags => tags)
    
    page.reload
    page.tags.should == tags
    
    page2.reload
    page.tags.should == tags
  end
  
  should "be able to pull with criteria and modifier hashes" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    
    @page_class.pull({:title => 'Home'}, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(bar)
    
    page2.reload
    page.tags.should == %w(bar)
  end
  
  should "be able to pull with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    
    @page_class.pull(page.id, page2.id, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(bar)
    
    page2.reload
    page.tags.should == %w(bar)
  end

  should "be able to pull all with criteria and modifier hashes" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
    page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
    
    @page_class.pull_all({:title => 'Home'}, :tags => %w(foo bar))
    
    page.reload
    page.tags.should == %w(baz)
    
    page2.reload
    page.tags.should == %w(baz)
  end
  
  should "be able to pull all with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
    page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
    
    @page_class.pull_all(page.id, page2.id, :tags => %w(foo bar))
    
    page.reload
    page.tags.should == %w(baz)
    
    page2.reload
    page.tags.should == %w(baz)
  end

  should "be able to push uniq with criteria and modifier hash" do
    page  = @page_class.create(:title => 'Home', :tags => 'foo')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.push_uniq({:title => 'Home'}, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(foo)
    
    page2.reload
    page.tags.should == %w(foo)
  end
  
  should "be able to push uniq with ids and modifier hash" do
    page  = @page_class.create(:title => 'Home', :tags => 'foo')
    page2 = @page_class.create(:title => 'Home')
    
    @page_class.push_uniq(page.id, page2.id, :tags => 'foo')
    
    page.reload
    page.tags.should == %w(foo)
    
    page2.reload
    page.tags.should == %w(foo)
  end
  
  should "be able to remove the last element the array" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    @page_class.pop(page.id, :tags => 1)
    page.reload
    page.tags.should == %w(foo)
  end

  should "be able to remove the first element of the array" do
    page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
    @page_class.pop(page.id, :tags => -1)
    page.reload
    page.tags.should == %w(bar)
  end
end