require 'test_helper'

class PaginationTest < Test::Unit::TestCase  
  context "Pagination proxy" do
    include MongoMapper::Pagination
    
    should "should have accessors for subject" do
      subject = [1,2,3,4,5]
      collection = PaginationProxy.new(25, 2)
      collection.subject = subject
      collection.subject.should == subject
    end
    
    should "delegate any methods not defined to the subject" do
      subject = [1,2,3,4,5]
      collection = PaginationProxy.new(25, 2, 10)
      collection.subject = subject
      collection.size.should == 5
      collection.each_with_index do |value, i|
        value.should == subject[i]
      end
      collection[0..2].should == [1,2,3]
      collection.class.should == Array
    end
    
    should "return correct value for total_entries" do
      PaginationProxy.new(25, 2, 10).total_entries.should == 25
      PaginationProxy.new('25', 2, 10).total_entries.should == 25
    end
    
    should "return correct value for per_page" do
      PaginationProxy.new(25, 2, 10).per_page.should == 10
      PaginationProxy.new(25, 2, '10').per_page.should == 10
    end
    
    should "alias limit to per_page" do
      PaginationProxy.new(100, 1, 300).limit.should == 300
    end
    
    should "set per_page to 25 if nil or blank" do
      PaginationProxy.new(25, 2).per_page.should == 25
      PaginationProxy.new(25, 2, '').per_page.should == 25
    end
    
    should "return correct value for current_page" do
      PaginationProxy.new(25, 2, 10).current_page.should == 2
      PaginationProxy.new(25, '2', 10).current_page.should == 2
    end
    
    should "not allow value less than 1 for current page" do
      PaginationProxy.new(25, -1).current_page.should == 1
    end
    
    should "automatically calculate total_pages from total_entries and per page" do
      PaginationProxy.new(25, 2, 10).total_pages.should == 3
    end
    
    should "know how many records to skip" do
      PaginationProxy.new(25, 2, 10).skip.should == 10
    end
    
    should "alias offset to skip" do
      PaginationProxy.new(25, 2, 10).offset.should == 10
    end
    
    context "previous_page" do
      should "be nil if current page 1" do
        PaginationProxy.new(25, 1, 10).previous_page.should be_nil
      end
      
      should "be one less than current page if current is > 1" do
        PaginationProxy.new(25, 2, 10).previous_page.should == 1
      end
    end
    
    context "next_page" do
      should "be nil if current page is last page" do
        PaginationProxy.new(25, 3, 10).next_page.should be_nil
      end
      
      should "work for any page that is not last" do
        PaginationProxy.new(25, 1, 10).next_page.should == 2
        PaginationProxy.new(25, 2, 10).next_page.should == 3
      end
    end
    
    context "previous_page" do
      should "be nil if current page is first page" do
        PaginationProxy.new(25, 1, 10).previous_page.should be_nil
      end
      
      should "work for any page other than first" do
        PaginationProxy.new(25, 2, 10).previous_page.should == 1
        PaginationProxy.new(25, 3, 10).previous_page.should == 2
      end
    end
    
    context "out_of_bounds?" do
      should "be true if current_page is greater than total_pages" do
        PaginationProxy.new(25, 10, 4).out_of_bounds?.should be_true
      end
      
      should "be false if current_page is less than total_pages" do
        PaginationProxy.new(25, 10, 1).out_of_bounds?.should be_false
        PaginationProxy.new(25, 2, 10).out_of_bounds?.should be_false
      end
      
      should "be false if current_page is equal to total_pages" do
        PaginationProxy.new(25, 3, 10).out_of_bounds?.should be_false
      end
    end
  end # end of pagination proxy
end # end of test case