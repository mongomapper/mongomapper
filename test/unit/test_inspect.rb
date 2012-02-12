require 'test_helper'

class InspectTest < Test::Unit::TestCase
  context "#inspect" do
    setup do
      @document = Doc('User') do
        key :name,  String
        key :age,   Integer
        key :email, String
      end

      @doc = @document.new(:name => 'John', :age => 29)
    end

    should "print out non-nil attributes in alpha sorted order" do
      @doc.inspect.should =~ /_id:.*, age: 29, name: "John"/
    end
    
    should "print out all attributes when (optional) include_super argument is true" do
      @doc.inspect(true).should =~ /_id:.*, age: 29, email: nil, name: "John"/
    end

    should "include class name" do
      @doc.inspect.should =~ /^#<User/
    end
    
    should "include embedded documents" do
      klass = Doc()
      pets = EDoc()

      klass.many :pets, :class => pets

      doc = klass.new(:pets => [{:name => "Kitten"}])
      doc.inspect.should =~ /_id:.*, pets: \[.*_id.*, name: "Kitten".*\]/
    end
    
    should "include embedded document" do
      klass = Doc()
      pet = EDoc()

      klass.one :pet, :class => pet

      doc = klass.new(:pet => {:name => "Kitten"})
      doc.inspect.should =~ /_id:.*, pet: .*_id.*, name: "Kitten".*/
    end
  end
end