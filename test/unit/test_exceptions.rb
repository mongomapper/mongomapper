require 'test_helper'

class ExtensionsTest < Test::Unit::TestCase
  context "DocumentNotValid" do
    should "have document reader method" do
      doc_class = Doc()
      instance  = doc_class.new
      exception = MongoMapper::DocumentNotValid.new(instance)
      exception.document.should == instance
    end
  end
end
