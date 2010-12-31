require 'test_helper'
# @pablocantero
class AutoIncrementTest < Test::Unit::TestCase
  context "autoincrementing" do
    setup do
      @klass = Doc do
        key :title, String
      end
      @klass.auto_increment!
    end

    should "set id on create" do
      doc = @klass.new(:title => 'The Simpsons Movie')
      doc.id.should be(nil)
      doc.save      
      doc.id.should_not be(nil)
      id = doc.id
      doc.save
      doc.id.should eql id
    end
    
    should "auto increment id" do
      doc = @klass.new(:title => 'Pirates of Silicon Valley')
      doc.save      
      doc2 = @klass.new(:title => 'Tropa de Elite')
      doc2.save
      (doc.id + 1).should eql doc2.id
    end
  end
end