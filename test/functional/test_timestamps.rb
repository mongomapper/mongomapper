require 'test_helper'

class TimestampsTest < Test::Unit::TestCase
  context "timestamping" do
    setup do
      @klass = Doc do
        key :first_name, String
        key :last_name, String
        key :age, Integer
        key :date, Date
      end
      @klass.timestamps!
    end

    should "set created_at and updated_at on create" do
      doc = @klass.new(:first_name => 'John', :age => 27)
      doc.created_at.should be(nil)
      doc.updated_at.should be(nil)
      doc.save
      doc.created_at.should_not be(nil)
      doc.updated_at.should_not be(nil)
    end

    should "not overwrite created_at if it already exists" do
      original_created_at = 1.month.ago
      doc = @klass.new(:first_name => 'John', :age => 27, :created_at => original_created_at)
      doc.created_at.to_i.should == original_created_at.to_i
      doc.updated_at.should be_nil
      doc.save
      doc.created_at.to_i.should == original_created_at.to_i
      doc.updated_at.should_not be_nil
    end

    should "set updated_at on field update but leave created_at alone" do
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

    should "set updated_at on document update but leave created_at alone" do
      doc = @klass.create(:first_name => 'John', :age => 27)
      old_created_at = doc.created_at.to_f

      new_updated_at = Time.now + 5.seconds
      Timecop.freeze(new_updated_at) do
        @klass.update(doc._id, { :first_name => 'Johnny' })
      end

      doc = doc.reload
      doc.created_at.to_f.should be_close(old_created_at, 0.001)
      doc.updated_at.to_f.should be_close(new_updated_at.to_f, 0.001)
    end
  end
end