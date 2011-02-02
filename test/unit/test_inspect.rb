require 'test_helper'

class InspectTest < Test::Unit::TestCase
  context "#inspect" do
    setup do
      @document = Doc('User') do
        key :name,  String
        key :age,   Integer
      end

      @doc = @document.new(:name => 'John', :age => 29)
    end

    should "print out attributes in alpha sorted order" do
      @doc.inspect.should =~ /_id:.*, age: 29, name: "John"/
    end

    should "include class name" do
      @doc.inspect.should =~ /^#<User/
    end
  end
end