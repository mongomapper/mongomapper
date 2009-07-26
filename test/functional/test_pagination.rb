require 'test_helper'

class PaginationTest < Test::Unit::TestCase
  context "Paginating" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        collection 'users'

        key :fname, String
        key :lname, String
        key :age, Integer
      end

      @document.collection.clear
      
      @doc1 = @document.create({:fname => 'John', :lname => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:fname => 'Steve', :lname => 'Smith', :age => '28'})
      @doc3 = @document.create({:fname => 'Steph', :lname => 'Nunemaker', :age => '26'})
    end

    should "return the total pages" do
      result = @document.paginate(:per_page => 2, :page => 1)
      result.total_pages.should == 2
    end

    should "return the total of records" do
      result = @document.paginate(:per_page => 2, :page => 1)
      result.total_entries.should == 3
    end

    should "return the items" do
      result = @document.paginate(:per_page => 2, :page => 1)
      result.size.should == 2
      result.subject.should == [@doc1, @doc2]
    end

    should "accept conditions" do
      result = @document.paginate({
        :conditions => {:lname => 'Nunemaker'},
        :order      => "age DESC",
        :per_page   => 2, 
        :page       => 1,
      })
      result.first.age.should == 27
    end
  end
end