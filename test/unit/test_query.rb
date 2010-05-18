require 'test_helper'
require 'models'

class QueryTest < Test::Unit::TestCase
  include MongoMapper

  should "raise error if provided something other than a hash" do
    lambda { Query.new(Room, nil) }.should raise_error(ArgumentError)
    lambda { Query.new(Room, 1) }.should raise_error(ArgumentError)
  end

  context "_type" do
    should "not add _type to query if model does not have superclass that is single collection inherited" do
      Query.new(Message, :foo => 'bar').criteria.to_hash.should == {
        :foo => 'bar'
      }
    end

    should "not add _type to nested conditions" do
      Query.new(Enter, :foo => 'bar', :age => {'$gt' => 21}).criteria.to_hash.should == {
        :foo => 'bar',
        :age => {'$gt' => 21},
        :_type => 'Enter'
      }
    end

    should "automatically add _type to query if model is single collection inherited" do
      Query.new(Enter, :foo => 'bar').criteria.to_hash.should == {
        :foo => 'bar',
        :_type => 'Enter'
      }
    end
  end
end
