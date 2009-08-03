require 'test_helper'

class PaginationTest < Test::Unit::TestCase
  context "Paginating" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        collection 'users'

        key :first_name, String
        key :last_name, String
        key :age, Integer
      end

      @document.collection.clear
      
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
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
      result = @document.paginate(:per_page => 2, :page => 1, :order => 'first_name')
      result.size.should == 2
      result.should == [@doc1, @doc3]
    end

    should "accept conditions" do
      result = @document.paginate({
        :conditions => {:last_name => 'Nunemaker'},
        :order      => "age DESC",
        :per_page   => 2, 
        :page       => 1,
      })
      result.should == [@doc1, @doc3]
      result.first.age.should == 27
    end
    
    should "withstand rigor" do
      result = @document.paginate({
        :per_page   => 1, 
        :page       => 1,
        :order      => 'age desc', 
        :conditions => {:last_name => 'Nunemaker'}
      })
      result.should == [@doc1]
      result.total_entries.should == 2
      result.total_pages.should == 2
      
      result = @document.paginate({
        :per_page   => 1,
        :page       => 2,
        :order      => 'age desc',
        :conditions => {:last_name => 'Nunemaker'}
      })
      result.should == [@doc3]
      result.total_entries.should == 2
      result.total_pages.should == 2
      
      result = @document.paginate({
        :per_page   => 2, 
        :page       => 1, 
        :order      => 'age desc',
        :conditions => {:last_name => 'Nunemaker'}
      })
      result.should == [@doc1, @doc3]
      result.total_entries.should == 2
      result.total_pages.should == 1
    end
  end
end