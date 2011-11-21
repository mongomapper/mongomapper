require 'test_helper'
require 'models'

class AliasingTest < Test::Unit::TestCase
  context "keys are aliased" do
    setup do
      @document = Doc do
        key :first_name, String, :alias => :f
        key :last_name, String, :alias => :l
        key :unaliased, String
      end

      @doc = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :unaliased => "foo")
    end
  
    should "store key aliases in db, not full keys" do
      raw_object = MongoMapper.connection[@document.database.name][@document.collection.name].find({"_id" => @doc.id}).first
      raw_object.include?("first_name").should == false
      raw_object["f"].should == "John"
      raw_object.include?("last_name").should == false
      raw_object["l"].should == "Nunemaker"
      raw_object["unaliased"].should == "foo"
    end
    
    should "create model with long keys when loaded from aliases model in db" do
      @doc.reload
      @doc.first_name.should == "John"
      @doc.last_name.should == "Nunemaker"
      @doc.unaliased.should == "foo"
    end
    
    should "serialize to_json with long keys" do
      json = ActiveSupport::JSON.encode(@doc)
      assert_no_match %r{"f"}, json
      assert_match %r{"first_name":"John"}, json
      assert_no_match %r{"l"}, json
      assert_match %r{"last_name":"Nunemaker"}, json
      assert_match %r{"unaliased":"foo"}, json
    end
    
    should "serialize to_xml with long keys" do
      xml = @doc.to_xml
      assert_no_match %r{<f>}, xml
      assert_match %r{<first-name>John</first-name>}, xml
      assert_no_match %r{<l>}, xml
      assert_match %r{<last-name>Nunemaker</last-name>}, xml
      assert_match %r{<unaliased>foo</unaliased>}, xml
    end
  end
end