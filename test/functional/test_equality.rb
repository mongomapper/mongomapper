require 'test_helper'

class Person
  include MongoMapper::Document

  one :address
end

class Address
  include MongoMapper::Document

  belongs_to :person
end

class EqualityTest < Test::Unit::TestCase
  context "Case equality" do
    should "work with proxies" do
      person = Person.create
      address = Address.create(:person => person)
      Person.should === address.person
      Address.should === person.address
    end
  end
end
