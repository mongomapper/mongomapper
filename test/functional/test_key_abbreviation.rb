require 'test_helper'
require 'models'

class KeyAbbreviationTest < Test::Unit::TestCase
  def setup
    @document = Doc do
      key :first_name, String, :abbr => :f
      key :last_name, String, :abbr => :l
      key :unabbreviated, String
      key :age, Integer, :abbr => :a
    end

    @doc = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :unabbreviated => "foo", :age => 27)
    @abe = @document.create(:first_name => 'Abe',  :last_name => 'Lincoln', :age => 200)
  end
  
  context "basic i/o of abbreviated keys" do
    should "store key abbreviation in db, not full keys" do
      raw_object = MongoMapper.connection[@document.database.name][@document.collection.name].find({"_id" => @doc.id}).first
      raw_object.include?("first_name").should == false
      raw_object["f"].should == "John"
      raw_object.include?("last_name").should == false
      raw_object["l"].should == "Nunemaker"
      raw_object["unabbreviated"].should == "foo"
    end
    
    should "create model with long keys when loaded from abbreviated model in db" do
      @doc.reload
      @doc.first_name.should == "John"
      @doc.last_name.should == "Nunemaker"
      @doc.unabbreviated.should == "foo"
    end
    
    should "serialize to_json with long keys" do
      json = ActiveSupport::JSON.encode(@doc)
      assert_no_match %r{"f"}, json
      assert_match %r{"first_name":"John"}, json
      assert_no_match %r{"l"}, json
      assert_match %r{"last_name":"Nunemaker"}, json
      assert_match %r{"unabbreviated":"foo"}, json
    end
    
    should "serialize to_xml with long keys" do
      xml = @doc.to_xml
      assert_no_match %r{<f>}, xml
      assert_match %r{<first-name>John</first-name>}, xml
      assert_no_match %r{<l>}, xml
      assert_match %r{<last-name>Nunemaker</last-name>}, xml
      assert_match %r{<unabbreviated>foo</unabbreviated>}, xml
    end
  end
  
  context "dynamic finders" do
    should "accept query on long key and perform mongo query on abbreviations" do
      d = @document.find_by_first_name('John')
      d.should == @doc
    end
    
    should "accept query on multiple abbreviated keys" do
      d = @document.find_by_first_name_and_last_name('John', 'Nunemaker')
      d.should == @doc
    end
    
    should "accept query on abbreviated and non-abbreviated keys" do
      d = @document.find_by_first_name_and_unabbreviated('John', 'foo')
      d.should == @doc
    end
    
    should "find all on abbreviated key" do
      d = @document.find_all_by_first_name('John')
      d.size.should == 1
      d[0].should == @doc
    end
  end
  
  context "querying with abbreviated keys" do
    should "find first from abbreviated key" do
      d = @document.first(:first_name => 'John')
      d.should == @doc
    end
    
    should "find last from abbreviated key" do
      d = @document.last(:first_name => 'John')
      d.should == @doc
    end
    
    should "count with abbreviated key" do
      @document.count(:first_name => 'John').should == 1
    end
    
    should "find all with abbreviated key" do
      d = @document.all(:first_name => 'John')
      d.size.should == 1
      d[0].should == @doc
    end
    
    should "accept abbreviated keys in where clause" do
      d = @document.where(:first_name => 'John').first
      d.should == @doc
    end
    
    should "accept abbreviated keys in where clause with symbol operators" do
      d = @document.where(:age.gt => 100).first
      d.should == @abe
      
      d2 = @document.where(:age.lt => 100).first
      d2.should == @doc
    end
    
    should "accept key abbreviation sorting w/ with symbol operators" do
      @document.sort(:last_name.asc).first.should == @abe
      @document.sort(:last_name.desc).first.should == @doc
    end
    
    should "accept key abbreviation with exist?" do
      @document.exist?(:first_name => 'John').should == true
    end
    
    should "accept key abbreviation with exists?" do
      @document.exists?(:first_name => 'John').should == true
    end
    
    should "accept key abbreviations when selecting fields" do
      d = @document.where(:first_name => 'John').fields(:last_name, :unabbreviated).first
      d.first_name.should == nil
      d.last_name.should == 'Nunemaker'
      d.unabbreviated.should == 'foo'
    end
    
    should "accept key abbreviation for normal sort operations" do
      d = @document.sort(:last_name).first
      d.should == @abe
    end
    
    should "accept key abbreviation for sort operations with symbol operators" do
      d = @document.sort(:age.asc).first
      d.should == @doc
    end
    
    should "accept mongo conditional operators on abbreviated keys" do
      d = @document.where(:age => {:$gt => 100, :$lt => 500}).first
      d.should == @abe
    end
    
    should "be able to string together query parts, all using abbreviations" do
      @document.sort(:age).where(:first_name => 'John').count(:last_name => 'Nunemaker').should == 1
      @document.sort(:age).where(:first_name => 'John').where(:last_name => 'Nunemaker').first(:unabbreviated => "foo").should == @doc
    end
    
    should "be able to find each using abbreviated keys in query" do
      count = 0
      @document.find_each(:age.gt => 1) do |d|
        count += 1
        (d == @doc || d == @abe).should == true
      end
      count.should == 2
    end


  end
end