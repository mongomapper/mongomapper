require 'test_helper'

class TimeTest < Test::Unit::TestCase
  context "time" do
    setup do
      @klass = Doc do
        key :name, String
        key :time, Time
      end
    end

    should "have same time after building new document and saving document" do
      doc = @klass.new(:name => "Bear", :time => Time.now.utc)
      old_time = doc.time
      doc.save
      doc.time.to_f.should eql(old_time.to_f)
    end

    should "have same time after creating and reloading document" do
      doc = @klass.create(:name => "Bear", :time => Time.now.utc)
      old_time = doc.time
      doc.reload
      doc.time.to_f.should eql(old_time.to_f)
    end

  end
end