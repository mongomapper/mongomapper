require 'spec_helper'

describe MongoMapper::Plugins::Document do
  describe ".embeddable?" do
    it "should return false for embeddable" do
      document.embeddable?.should be_false
    end
  end

  context "an instance" do
    context "new?" do
      it "should be true if new" do
        document.new.new?.should be_true
      end

      it "should be true if custom id and not saved yet" do
        document.key :_id, String
        doc = silence_stderr { document.new }
        doc.id = '1234'
        doc.new?.should be_true
      end
    end
  end
end

