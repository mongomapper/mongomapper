require 'spec_helper'

describe "Timestamps" do
  context "included" do
    before do
      @klass = Doc do
        key :first_name, String
      end
      @klass.timestamps!
    end

    it "should set record_timestamps to true" do
      @klass.record_timestamps.should be(true)
    end
  end

  context "timestamping" do
    before do
      @klass = Doc do
        key :first_name, String
        key :last_name, String
        key :age, Integer
        key :date, Date
      end
      @klass.timestamps!
    end

    context "when #record_timestamps is set to true" do
      it "should set created_at and updated_at on create" do
        doc = @klass.new(:first_name => 'John', :age => 27)
        doc.created_at.should be(nil)
        doc.updated_at.should be(nil)
        doc.save
        doc.created_at.should_not be(nil)
        doc.updated_at.should_not be(nil)
      end

      it "should not overwrite created_at if it already exists" do
        original_created_at = 1.month.ago
        doc = @klass.new(:first_name => 'John', :age => 27, :created_at => original_created_at)
        doc.created_at.to_i.should == original_created_at.to_i
        doc.updated_at.should be_nil
        doc.save
        doc.created_at.to_i.should == original_created_at.to_i
        doc.updated_at.should_not be_nil
      end

      it "should set updated_at on field update but leave created_at alone" do
        doc = @klass.create(:first_name => 'John', :age => 27)
        old_created_at = doc.created_at
        old_updated_at = doc.updated_at
        doc.first_name = 'Johnny'

        Timecop.freeze(Time.now + 5.seconds) do
          doc.save
        end

        doc.created_at.should == old_created_at
        doc.updated_at.should_not == old_updated_at
      end

      it "should set updated_at on document update but leave created_at alone" do
        doc = @klass.create(:first_name => 'John', :age => 27)
        old_created_at = doc.created_at.to_i

        new_updated_at = Time.at(Time.now.to_i + 5.seconds)
        Timecop.freeze(new_updated_at) do
          @klass.update(doc._id, { :first_name => 'Johnny' })
        end

        doc = doc.reload
        doc.created_at.to_i.should be_within(1).of(old_created_at.to_i)
        doc.updated_at.to_i.should be_within(1).of(new_updated_at.to_i)
      end

      it "should have #first return the first created object" do
        doc2 = @klass.create!(:created_at => Time.now)
        doc1 = @klass.create!(:created_at => 1.week.ago)

        @klass.first.should == doc1
      end

      it "should have #last return the last created object" do
        doc2 = @klass.create!(:created_at => Time.now)
        doc1 = @klass.create!(:created_at => 1.week.ago)

        @klass.last.should == doc2
      end

      it "should allow sorting by something else" do
        john = @klass.create!(:first_name => "John", :created_at => 6.months.ago)
        chris = @klass.create!(:first_name => "Chris", :created_at => 3.weeks.ago)

        @klass.first(:order => :first_name).should == chris
        @klass.sort(:first_name).first.should == chris

        @klass.last(:order => :first_name).should == john
        @klass.sort(:first_name).last.should == john
      end
    end

    context "when #record_timestamps is set to false" do
      before do
        @klass.record_timestamps = false
      end

      after do
        @klass.record_timestamps = true
      end

      it "should not set created_at on document create" do
        doc = @klass.create(:first_name => "John")
        doc.created_at.should be_nil
      end

      it "should not set updated_at on document create" do
        doc = @klass.create(:first_name => "John")
        doc.updated_at.should be_nil
      end
    end
  end
end
