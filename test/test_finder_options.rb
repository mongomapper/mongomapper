require 'test_helper'

class FinderOptionsTest < Test::Unit::TestCase
  include MongoMapper
  
  should "raise error if provided something other than a hash" do
    lambda { FinderOptions.new }.should raise_error(ArgumentError)
    lambda { FinderOptions.new(1) }.should raise_error(ArgumentError)
  end
  
  should "have symbolize the keys of the hash provided" do
    FinderOptions.new('offset' => 1).options.keys.map do |key|
      key.should be_instance_of(Symbol)
    end
  end
  
  context "Converting conditions to criteria" do
    should "work with simple criteria" do
      FinderOptions.new(:conditions => {:foo => 'bar'}).criteria.should == {
        :foo => 'bar'
      }
      
      FinderOptions.new(:conditions => {:foo => 'bar', :baz => 'wick'}).criteria.should == {
        :foo => 'bar', 
        :baz => 'wick'
      }
    end
    
    should "use $in for arrays" do
      FinderOptions.new(:conditions => {:foo => [1,2,3]}).criteria.should == {
        :foo => {'$in' => [1,2,3]}
      }
    end
    
    should "work arbitrarily deep" do
      FinderOptions.new(:conditions => {:foo => {:bar => [1,2,3]}}).criteria.should == {
        :foo => {:bar => {'$in' => [1,2,3]}}
      }
    end
  end
  
  context "ordering" do
    should "single field with ascending direction" do
      hash = OrderedHash.new
      hash[:foo] = 1
      FinderOptions.new(:order => 'foo asc').options[:sort].should == hash
      FinderOptions.new(:order => 'foo ASC').options[:sort].should == hash
    end
    
    should "single field with descending direction" do
      hash = OrderedHash.new
      hash[:foo] = -1
      FinderOptions.new(:order => 'foo desc').options[:sort].should == hash
      FinderOptions.new(:order => 'foo DESC').options[:sort].should == hash
    end
    
    should "convert field without direction to ascending" do
      hash = OrderedHash.new
      hash[:foo] = 1
      FinderOptions.new(:order => 'foo').options[:sort].should == hash
    end
    
    should "convert multiple fields with directions" do
      hash = OrderedHash.new
      hash[:foo] = -1
      hash[:bar] = 1
      hash[:baz] = -1
      options = FinderOptions.new(:order => 'foo desc, bar asc, baz desc').options[:sort].should == hash
    end
    
    should "convert multiple fields with some missing directions" do
      hash = OrderedHash.new
      hash[:foo] = -1
      hash[:bar] = 1
      hash[:baz] = 1
      options = FinderOptions.new(:order => 'foo desc, bar, baz').options[:sort].should == hash
    end
  end
  
  context "offset" do
    should "default to 0" do
      FinderOptions.new({}).options[:offset].should == 0
    end
    
    should "use offset provided" do
      FinderOptions.new(:offset => 2).options[:offset].should == 2
    end
    
    should "covert string to integer" do
      FinderOptions.new(:offset => '2').options[:offset].should == 2
    end
  end
  
  context "limit" do
    should "default to 0" do
      FinderOptions.new({}).options[:limit].should == 0
    end
    
    should "use offset provided" do
      FinderOptions.new(:limit => 2).options[:limit].should == 2
    end
    
    should "covert string to integer" do
      FinderOptions.new(:limit => '2').options[:limit].should == 2
    end
  end
  
  context "fields" do
    should "default to nil" do
      FinderOptions.new({}).options[:fields].should be(nil)
    end
    
    should "be converted to nil if {}" do
      FinderOptions.new(:fields => {}).options[:fields].should be(nil)
    end
    
    should "should work with array" do
      FinderOptions.new({:fields => ['a', 'b']}).options[:fields].should == ['a', 'b']
    end
    
    should "convert comma separated list to array" do
      FinderOptions.new({:fields => 'a, b'}).options[:fields].should == ['a', 'b']
    end
  end
end # FinderOptionsTest
