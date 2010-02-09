require 'test_helper'

class SupportTest < Test::Unit::TestCase
  context "Array#to_mongo" do
    should "convert value to_a" do
      Array.to_mongo([1, 2, 3, 4]).should == [1, 2, 3, 4]
      Array.to_mongo('1').should == ['1']
      Array.to_mongo({'1' => '2', '3' => '4'}).should == [['1', '2'], ['3', '4']]
    end
  end

  context "Array#from_mongo" do
    should "be array if array" do
      Array.from_mongo([1, 2]).should == [1, 2]
    end
    
    should "be empty array if nil" do
      Array.from_mongo(nil).should == []
    end
  end
  
  context "Binary#to_mongo" do
    should "convert to byte buffer if not byte buffer" do
      Binary.to_mongo('asdfsadasdfs').is_a?(ByteBuffer).should be_true
    end
    
    should "be byte buffer if byte buffer" do
      Binary.to_mongo(ByteBuffer.new('asdfsadasdfs')).is_a?(ByteBuffer).should be_true
    end
    
    should "be nil if nil" do
      Binary.to_mongo(nil).should be_nil
    end
  end
  
  context "Binary#from_mongo" do
    should "return value" do
      buffer = ByteBuffer.new('asdfasdfasdf')
      Binary.from_mongo(buffer).to_s.should == buffer.to_s
    end
  end
  
  context "Boolean#to_mongo" do
    should "be true for true" do
      Boolean.to_mongo(true).should be_true
    end
    
    should "be false for false" do
      Boolean.to_mongo(false).should be_false
    end
    
    should "handle odd assortment of other values" do
      Boolean.to_mongo('true').should be_true
      Boolean.to_mongo('t').should be_true
      Boolean.to_mongo('1').should be_true
      Boolean.to_mongo(1).should be_true
      
      Boolean.to_mongo('false').should be_false
      Boolean.to_mongo('f').should be_false
      Boolean.to_mongo('0').should be_false
      Boolean.to_mongo(0).should be_false
    end
  end
  
  context "Boolean#from_mongo" do
    should "be true for true" do
      Boolean.from_mongo(true).should be_true
    end
    
    should "be false for false" do
      Boolean.from_mongo(false).should be_false
    end
    
    should "be false for nil" do
      Boolean.from_mongo(nil).should be_false
    end
  end
  
  context "Date#to_mongo" do
    should "be time if string" do
      date = Date.to_mongo('10/1/2009')
      date.should == Time.utc(2009, 10, 1)
      date.should == date
      date.month.should == 10
      date.day.should == 1
      date.year.should == 2009
    end
    
    should "be time if date" do
      Date.to_mongo(Date.new(2009, 10, 1)).should == Time.utc(2009, 10, 1)
    end
    
    should "be date if time" do
      Date.to_mongo(Time.parse("2009-10-1T12:30:00")).should == Time.utc(2009, 10, 1)
    end
    
    should "be nil if bogus string" do
      Date.to_mongo('jdsafop874').should be_nil
    end
    
    should "be nil if empty string" do
      Date.to_mongo('').should be_nil
    end
  end
  
  context "Date#from_mongo" do
    should "be date if date" do
      date = Date.new(2009, 10, 1)
      from_date = Date.from_mongo(date)
      from_date.should == date
      from_date.month.should == 10
      from_date.day.should == 1
      from_date.year.should == 2009
    end
    
    should "be date if time" do
      time = Time.now
      Date.from_mongo(time).should == time.to_date
    end
    
    should "be nil if nil" do
      Date.from_mongo(nil).should be_nil
    end
  end
  
  context "Float#to_mongo" do
    should "convert value to_f" do
      [21, 21.0, '21'].each do |value|
        Float.to_mongo(value).should == 21.0
      end
    end
  end
  
  context "Hash#from_mongo" do
    should "convert hash to hash with indifferent access" do
      hash = Hash.from_mongo(:foo => 'bar')
      hash[:foo].should  == 'bar'
      hash['foo'].should == 'bar'
    end
    
    should "be hash if nil" do
      hash = Hash.from_mongo(nil)
      hash.should == {}
      hash.is_a?(HashWithIndifferentAccess).should be_true
    end
  end
  
  context "Hash#to_mongo instance method" do
    should "have instance method that returns self" do
      hash = HashWithIndifferentAccess.new('foo' => 'bar')
      hash.to_mongo.should == {'foo' => 'bar'}
    end
  end
  
  context "Integer#to_mongo" do
    should "convert value to integer" do
      [21, 21.0, '21'].each do |value|
        Integer.to_mongo(value).should == 21
      end
    end
    
    should "work fine with big integers" do
      [9223372036854775807, '9223372036854775807'].each do |value|
        Integer.to_mongo(value).should == 9223372036854775807
      end
    end
  end
  
  context "ObjectId#to_mongo" do
    should "return nil for nil" do
      ObjectId.to_mongo(nil).should be_nil
    end
    
    should "return nil if blank string" do
      ObjectId.to_mongo('').should be_nil
    end
    
    should "return value if object id" do
      id = Mongo::ObjectID.new
      ObjectId.to_mongo(id).should be(id)
    end
    
    should "return object id if string" do
      id = Mongo::ObjectID.new
      ObjectId.to_mongo(id.to_s).should be(id)
    end
  end
  
  context "ObjectId#from_mongo" do
    should "return value" do
      id = Mongo::ObjectID.new
      ObjectId.from_mongo(id).should == id
    end
  end
  
  context "NilClass#to_mongo" do
    should "return nil" do
      nil.to_mongo(nil).should be_nil
    end
  end
  
  context "NilClass#from_mongo" do
    should "return nil" do
      nil.from_mongo(nil).should be_nil
    end
  end
  
  context "Object#to_mongo" do
    should "return value" do
      Object.to_mongo(21).should == 21
      Object.to_mongo('21').should == '21'
      Object.to_mongo(9223372036854775807).should == 9223372036854775807
    end
  end
  
  context "Object#from_mongo" do
    should "return value" do
      Object.from_mongo(21).should == 21
      Object.from_mongo('21').should == '21'
      Object.from_mongo(9223372036854775807).should == 9223372036854775807
    end
  end
  
  context "Set#to_mongo" do
    should "convert value to_a" do
      Set.to_mongo(Set.new([1,2,3])).should == [1,2,3]
    end

    should "convert to empty array if nil" do
      Set.to_mongo(nil).should == []
    end
  end

  context "Set#from_mongo" do
    should "be a set if array" do
      Set.from_mongo([1,2,3]).should == Set.new([1,2,3])
    end

    should "be empty set if nil" do
      Set.from_mongo(nil).should == Set.new([])
    end
  end
  
  context "String#to_mongo" do
    should "convert value to_s" do
      [21, '21'].each do |value|
        String.to_mongo(value).should == '21'
      end
    end
    
    should "be nil if nil" do
      String.to_mongo(nil).should be_nil
    end
  end

  context "String#from_mongo" do
    should "be string if value present" do
      String.from_mongo('Scotch! Scotch! Scotch!').should == 'Scotch! Scotch! Scotch!'
    end
    
    should "return nil if nil" do
      String.from_mongo(nil).should be_nil
    end
    
    should "return empty string if blank" do
      String.from_mongo('').should == ''
    end
  end
  
  context "Symbol" do
    %w(gt lt gte lte ne in nin mod all size where exists asc desc).each do |operator|
      should "have $#{operator} operator" do
        :foo.respond_to?(operator)
      end
    end
  end
  
  context "Time#to_mongo without Time.zone" do
    should "be time to milliseconds if string" do
      Time.to_mongo('2000-01-01 01:01:01.123456').should == Time.local(2000, 1, 1, 1, 1, 1, 123000).utc
    end
    
    should "be time in utc if time" do
      Time.to_mongo(Time.local(2009, 8, 15, 0, 0, 0)).zone.should == 'UTC'
    end
    
    should "be nil if blank string" do
      Time.to_mongo('').should be_nil
    end
    
    should "not be nil if nil" do
      Time.to_mongo(nil).should be_nil
    end
  end
  
  context "Time#to_mongo with Time.zone" do
    should "be time to milliseconds if time" do
      Time.zone = 'Hawaii'
      Time.to_mongo(Time.zone.local(2009, 8, 15, 14, 0, 0, 123456)).should == Time.utc(2009, 8, 16, 0, 0, 0, 123000)
      Time.zone = nil
    end

    should "be time to milliseconds if string" do
      Time.zone = 'Hawaii'
      Time.to_mongo('2009-08-15 14:00:00.123456').should == Time.utc(2009, 8, 16, 0, 0, 0, 123000)
      Time.zone = nil
    end
    
    should "be nil if blank string" do
      Time.zone = 'Hawaii'
      Time.to_mongo('').should be_nil
      Time.zone = nil
    end
    
    should "be nil if nil" do
      Time.zone = 'Hawaii'
      Time.to_mongo(nil).should be_nil
      Time.zone = nil
    end
  end
  
  context "Time#from_mongo without Time.zone" do
    should "be time" do
      time = Time.now
      Time.from_mongo(time).should == time
    end
    
    should "be nil if nil" do
      Time.from_mongo(nil).should be_nil
    end
  end
  
  context "Time#from_mongo with Time.zone" do
    should "be time in Time.zone" do
      Time.zone = 'Hawaii'
      
      time = Time.from_mongo(Time.utc(2009, 10, 1))
      time.should == Time.zone.local(2009, 9, 30, 14)
      time.is_a?(ActiveSupport::TimeWithZone).should be_true
      
      Time.zone = nil
    end
    
    should "be nil if nil" do
      Time.zone = 'Hawaii'
      Time.from_mongo(nil).should be_nil
      Time.zone = nil
    end
  end
  
  context "Mongo::ObjectID.to_json" do
    should "convert object id to string" do
      id = Mongo::ObjectID.new
      id.to_json.should == %Q("#{id}")
    end
    
    should "support ruby driver syntax also" do
      id = Mongo::ObjectID.new
      id.original_to_json.should == %Q({"$oid": "#{id}"})
    end
  end
end