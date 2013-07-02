require 'spec_helper'

describe "Equality" do
  context "Case equality" do
    before do
      @person = Doc()
      @address = Doc()

      @person.one :address, :class => @address, :foreign_key => :person_id
      @address.belongs_to :person, :class => @person
    end

    it "should work with proxies" do
      person = @person.create!
      address = @address.create!(:person => person)
      @person.should === address.person
      @address.should === person.address
    end
  end
end
