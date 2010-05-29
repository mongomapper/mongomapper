require 'test_helper'

class PaginationTest < Test::Unit::TestCase
  should "default per_page to 25" do
    Doc().per_page.should == 25
  end

  should "allow overriding per_page" do
    Doc() { def self.per_page; 1 end }.per_page.should == 1
  end
end