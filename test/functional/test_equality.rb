require 'test_helper'

class EqualityTest < Test::Unit::TestCase
  context "Case equality" do
    setup do
      @person = Doc()
      @address = Doc()

      @person.one :address, :class => @address, :foreign_key => :person_id
      @address.belongs_to :person, :class => @person
    end

    should "work with proxies" do
      person = @person.create!
      address = @address.create!(:person => person)
      @person.should === address.person
      @address.should === person.address
    end
  end
end
