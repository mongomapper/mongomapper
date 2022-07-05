require 'spec_helper'

describe "Inspect" do
  context "#inspect" do
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

    it "should include embedded documents" do
      klass = Doc()
      pets = EDoc()

      klass.many :pets, :class => pets

      doc = klass.new(:pets => [{:name => "Kitten"}])
      doc.inspect.should =~ /_id:.*, pets: .*\[.*_id.*, name: "Kitten".*\]/
    end

    it "should include embedded document" do
      klass = Doc()
      pet = EDoc()

      klass.one :pet, :class => pet

      doc = klass.new(:pet => {:name => "Kitten"})
      doc.inspect.should =~ /_id:.*, pet: .*_id.*, name: "Kitten".*/
    end
  end

  context "#inspect with filter_attributes" do
    before do
      MongoMapper::Utils.remove_instance_variable(:@filter) if MongoMapper::Utils.instance_variable_defined?(:@filter)
      MongoMapper.filter_attributes = [:email, :card_number, :phone_number]
    end

    after do
      MongoMapper.filter_attributes =[]
      MongoMapper::Utils.remove_instance_variable(:@filter) if MongoMapper::Utils.instance_variable_defined?(:@filter)
    end

    it "should filter the fields given by filter_attributes" do
      document = Doc('User') do
        key :name,  String
        key :age,   Integer
        key :email, String
        key :card_number, String
      end
      doc = document.new(
        :name => 'John',
        :age => 29,
        :email => 'mongomapper@example.com',
        :card_number => '123'
      )

      if ActiveSupport.version >= Gem::Version.new("6.0")
        doc.inspect.should =~ /_id:.*, age: 29, card_number: \[FILTERED\], email: \[FILTERED\], name: "John"/
      else
        doc.inspect.should =~ /_id:.*, age: 29, card_number: "123", email: "mongomapper@example.com", name: "John"/
      end
    end

    it "should filter the fields given by filter_attributes for embedded document" do
      document = EDoc('Profile') do
        key :job,  String
        key :phone_number,  String
      end
      doc = document.new(
        :job => 'Software Engineer',
        :phone_number => '09011110000'
      )

      if ActiveSupport.version >= Gem::Version.new("6.0")
        doc.inspect.should =~ /job: "Software Engineer", phone_number: \[FILTERED\]/
      else
        doc.inspect.should =~ /job: "Software Engineer", phone_number: "09011110000"/
      end
    end
  end
end
