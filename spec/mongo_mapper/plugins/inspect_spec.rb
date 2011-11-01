require 'spec_helper'

describe MongoMapper::Plugins::Inspect do
  describe "#inspect" do
    before do
      @document = Doc('User') do
        key :name,  String
        key :age,   Integer
        key :email, String
      end

      @doc = @document.new(:name => 'John', :age => 29)
    end

    it "should print out non-nil attributes in alpha sorted order" do
      @doc.inspect.should =~ /_id:.*, age: 29, name: "John"/
    end

    it "should print out all attributes when (optional) include_super argument is true" do
      @doc.inspect(true).should =~ /_id:.*, age: 29, email: nil, name: "John"/
    end

    it "should include class name" do
      @doc.inspect.should =~ /^#<User/
    end
  end
end