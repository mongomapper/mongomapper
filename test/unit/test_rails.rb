require 'test_helper'

class TestRails < Test::Unit::TestCase
  context "Document" do
    setup do
      @klass = Doc('Post') do
        key :foo, String
      end
    end

    should "alias has_many to many" do
      @klass.should respond_to(:has_many)
    end
    
    should "alias has_one to one" do
      @klass.should respond_to(:has_one)
    end
    
    should "alias new_record? to new?" do
      instance = @klass.new
      instance.new_record?.should == instance.new?
    end
    
    should "have column names" do
      @klass.column_names.sort.should == ['_id', 'foo']
    end
    
    should "implement human_name" do
      @klass.human_name.should == 'Post'
    end
  end
  
  context "EmbeddedDocument" do
    setup do
      @klass = EDoc('Post') do
        key :foo, String
      end
      
      @comment = EDoc('Comment')
      @author = EDoc('Author')
    end
    
    should "alias has_many to many" do
      @klass.has_many(:comments, :class => @comment).should == @klass.many(:comments, :class => @comment)
    end
    
    should "alias has_one to one" do
      @klass.has_one(:comment, :class => @author).should == @klass.one(:comment, :class => @author)
    end
    
    should "alias new_record? to new?" do
      instance = @klass.new
      instance.new_record?.should == instance.new?
    end
    
    should "have column names" do
      @klass.column_names.sort.should == ['_id', 'foo']
    end
    
    should "implement human_name" do
      @klass.human_name.should == 'Post'
    end
  end
end