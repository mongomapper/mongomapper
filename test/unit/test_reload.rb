require 'test_helper'
require 'models'

class ReloadTest < Test::Unit::TestCase
  context "reload" do

    should "work" do
      doc = Answer.new
      doc.body = "some answer."
      doc.save!

      another_doc = Answer.find(doc.id)
      another_doc.body.should == doc.body


      doc.body= nil
      doc.save!
      another_doc.reload
      another_doc.body.should be_nil
    end
   end

end

