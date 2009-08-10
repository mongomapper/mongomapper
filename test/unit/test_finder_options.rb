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
  
  context "#criteria" do
    should "convert conditions to criteria" do
      FinderOptions.expects(:to_mongo_criteria).with(:foo => 1).returns({})
      FinderOptions.new(:conditions => {:foo => 1}).criteria
    end
  end
  
  context "#options" do
    should "convert options to mongo options" do
      FinderOptions.expects(:to_mongo_options).with(:order => 'foo asc', :select => 'foo,bar').returns({})
      FinderOptions.new(:order => 'foo asc', :select => 'foo,bar').options
    end
  end
  
  context "Converting conditions to criteria" do
    should "work with simple criteria" do
      FinderOptions.to_mongo_criteria(:foo => 'bar').should == {
        :foo => 'bar'
      }
      
      FinderOptions.to_mongo_criteria(:foo => 'bar', :baz => 'wick').should == {
        :foo => 'bar', 
        :baz => 'wick'
      }
    end
    
    should "use $in for arrays" do
      FinderOptions.to_mongo_criteria(:foo => [1,2,3]).should == {
        :foo => {'$in' => [1,2,3]}
      }
    end
    
    should "not use $in for arrays if already using array operator" do
      FinderOptions.to_mongo_criteria(:foo => {'$all' => [1,2,3]}).should == {
        :foo => {'$all' => [1,2,3]}
      }

      FinderOptions.to_mongo_criteria(:foo => {'$any' => [1,2,3]}).should == {
        :foo => {'$any' => [1,2,3]}
      }
    end
    
    should "work arbitrarily deep" do
      FinderOptions.to_mongo_criteria(:foo => {:bar => [1,2,3]}).should == {
        :foo => {:bar => {'$in' => [1,2,3]}}
      }
      
      FinderOptions.to_mongo_criteria(:foo => {:bar => {'$any' => [1,2,3]}}).should == {
        :foo => {:bar => {'$any' => [1,2,3]}}
      }
    end
  end
  
  context "ordering" do
    should "single field with ascending direction" do
      hash = OrderedHash.new
      hash[:foo] = 1
      FinderOptions.to_mongo_options(:order => 'foo asc')[:sort].should == hash
      FinderOptions.to_mongo_options(:order => 'foo ASC')[:sort].should == hash
    end
    
    should "single field with descending direction" do
      hash = OrderedHash.new
      hash[:foo] = -1
      FinderOptions.to_mongo_options(:order => 'foo desc')[:sort].should == hash
      FinderOptions.to_mongo_options(:order => 'foo DESC')[:sort].should == hash
    end
    
    should "convert field without direction to ascending" do
      hash = OrderedHash.new
      hash[:foo] = 1
      FinderOptions.to_mongo_options(:order => 'foo')[:sort].should == hash
    end
    
    should "convert multiple fields with directions" do
      hash = OrderedHash.new
      hash[:foo] = -1
      hash[:bar] = 1
      hash[:baz] = -1
      FinderOptions.to_mongo_options(:order => 'foo desc, bar asc, baz desc')[:sort].should == hash
    end
    
    should "convert multiple fields with some missing directions" do
      hash = OrderedHash.new
      hash[:foo] = -1
      hash[:bar] = 1
      hash[:baz] = 1
      FinderOptions.to_mongo_options(:order => 'foo desc, bar, baz')[:sort].should == hash
    end
    
    should "just use sort if sort and order are present" do
      FinderOptions.to_mongo_options(:sort => {'$natural' => 1}, :order => 'foo asc')[:sort].should == {
        '$natural' => 1
      }
    end
    
    should "convert natural in order to proper" do
      hash = OrderedHash.new
      hash[:'$natural'] = 1
      FinderOptions.to_mongo_options(:order => '$natural asc')[:sort].should == hash
      hash[:'$natural'] = -1
      FinderOptions.to_mongo_options(:order => '$natural desc')[:sort].should == hash
    end
    
    should "work for natural order ascending" do
      FinderOptions.to_mongo_options(:sort => {'$natural' => 1})[:sort]['$natural'].should == 1
    end
    
    should "work for natural order descending" do
      FinderOptions.to_mongo_options(:sort => {'$natural' => -1})[:sort]['$natural'].should == -1
    end
  end
  
  context "offset" do
    should "default to 0" do
      FinderOptions.to_mongo_options({})[:offset].should == 0
    end
    
    should "use offset provided" do
      FinderOptions.to_mongo_options(:offset => 2)[:offset].should == 2
    end
    
    should "covert string to integer" do
      FinderOptions.to_mongo_options(:offset => '2')[:offset].should == 2
    end
  end
  
  context "limit" do
    should "default to 0" do
      FinderOptions.to_mongo_options({})[:limit].should == 0
    end
    
    should "use offset provided" do
      FinderOptions.to_mongo_options(:limit => 2)[:limit].should == 2
    end
    
    should "covert string to integer" do
      FinderOptions.to_mongo_options(:limit => '2')[:limit].should == 2
    end
  end
  
  context "fields" do
    should "default to nil" do
      FinderOptions.to_mongo_options({})[:fields].should be(nil)
    end
    
    should "be converted to nil if empty string" do
      FinderOptions.to_mongo_options(:fields => '')[:fields].should be(nil)
    end
    
    should "be converted to nil if []" do
      FinderOptions.to_mongo_options(:fields => [])[:fields].should be(nil)
    end
    
    should "should work with array" do
      FinderOptions.to_mongo_options({:fields => %w(a b)})[:fields].should == %w(a b)
    end
    
    should "convert comma separated list to array" do
      FinderOptions.to_mongo_options({:fields => 'a, b'})[:fields].should == %w(a b)
    end
    
    should "also work as select" do
      FinderOptions.new(:select => %w(a b)).options[:fields].should == %w(a b)
    end
  end
end # FinderOptionsTest
