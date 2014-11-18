require 'spec_helper'

describe "TimeZones" do
  context "An instance of an embedded document" do
    before do
      @document = EDoc do
        key :name, String
        key :created_at, Time
      end
    end

    it "should preserve milliseconds" do
      doc = @document.new(:created_at => '2011-02-12 16:01:02.543Z')
      doc.created_at.should be_within(0.0000001).of(Time.parse('2011-02-12 16:01:02.543Z'))
    end

    it "should work without Time.zone" do
      Time.zone = nil

      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.should == Time.local(2009, 8, 15, 14, 0, 0).utc
    end

    it "should work with Time.zone set to the (default) UTC" do
      Time.zone = 'UTC'

      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.is_a?(ActiveSupport::TimeWithZone).should be_truthy
      doc.created_at.should == Time.utc(2009, 8, 15, 14)

      Time.zone = nil
    end

    it "should work with timezones that are not UTC" do
      Time.zone = 'Hawaii'

      doc = @document.new(:created_at => "2009-08-15 14:00:00")
      doc.created_at.is_a?(ActiveSupport::TimeWithZone).should be_truthy
      doc.created_at.should == Time.utc(2009, 8, 16)

      Time.zone = nil
    end
  end
end