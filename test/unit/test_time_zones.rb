require 'test_helper'

class TimeZonesTest < Test::Unit::TestCase
  context "An instance of an embedded document" do
    setup do      
      @document = EDoc do
        key :name, String
        key :created_at, Time
      end
    end
    
    should "work without Time.zone" do
      Time.zone = nil
      
      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.should == Time.local(2009, 8, 15, 14, 0, 0).utc
    end
    
    should "work with Time.zone set to the (default) UTC" do
      Time.zone = 'UTC'
      
      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.is_a?(ActiveSupport::TimeWithZone).should be_true
      doc.created_at.should == Time.utc(2009, 8, 15, 14)
      
      Time.zone = nil
    end
    
    should "work with timezones that are not UTC" do
      Time.zone = 'Hawaii'
      
      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.is_a?(ActiveSupport::TimeWithZone).should be_true
      doc.created_at.should == Time.utc(2009, 8, 16)
      
      Time.zone = nil
    end
  end
end