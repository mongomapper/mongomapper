require 'test_helper'

class DynamicQueryingTest < Test::Unit::TestCase
  def setup
    @document = Doc do
      scope :nunes, where(:last_name => 'Nunemaker')

      key :first_name, String
      key :last_name, String
      key :age, Integer
      key :date, Date
    end

    @doc1 = @document.create(:first_name => 'John',   :last_name => 'Nunemaker', :age => 27)
    @doc2 = @document.create(:first_name => 'Steve',  :last_name => 'Smith',     :age => 28)
    @doc3 = @document.create(:first_name => 'Steph',  :last_name => 'Nunemaker', :age => 26)
  end

  should "find document based on argument" do
    @document.find_by_first_name('John').should == @doc1
    @document.find_by_last_name('Nunemaker', :order => 'age desc').should == @doc1
    @document.find_by_age(27).should == @doc1
  end

  should "not raise error" do
    @document.find_by_first_name('Mongo').should be_nil
  end

  should "define a method for each key" do
    @document.methods(false).select { |e| e =~ /^find_by_/ }.size == @document.keys.size
  end

  should "find document based on all arguments" do
    @document.find_by_first_name_and_last_name_and_age('John', 'Nunemaker', 27).should == @doc1
  end

  should "not find the document if an argument is wrong" do
    @document.find_by_first_name_and_last_name_and_age('John', 'Nunemaker', 28).should be_nil
  end

  should "find all documents based on arguments" do
    docs = @document.find_all_by_last_name('Nunemaker')
    docs.should be_kind_of(Array)
    docs.should include(@doc1)
    docs.should include(@doc3)
  end

  should "initialize document with given arguments" do
    doc = @document.find_or_initialize_by_first_name_and_last_name('David', 'Cuadrado')
    doc.should be_new
    doc.first_name.should == 'David'
  end

  should "not initialize document if document is found" do
    doc = @document.find_or_initialize_by_first_name('John')
    doc.should_not be_new
  end

  should "create document with given arguments" do
    doc = @document.find_or_create_by_first_name_and_last_name('David', 'Cuadrado')
    doc.should_not be_new
    doc.first_name.should == 'David'
  end

  should "raise error if document is not found when using !" do
    lambda {
      @document.find_by_first_name_and_last_name!(1,2)
    }.should raise_error(MongoMapper::DocumentNotFound)
  end

  should "work on scopes" do
    @document.nunes.find_by_first_name('Steph').should == @doc3
    @document.nunes.find_all_by_first_name('Steph').should == [@doc3]
  end
end