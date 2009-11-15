require 'test_helper'
require 'models'

class BelongsToProxyTest < Test::Unit::TestCase
  def setup    
    @post_class = Class.new do
      include MongoMapper::Document
    end
    
    @comment_class = Class.new do
      include MongoMapper::Document
      key :post_id, String
    end
    @comment_class.belongs_to :post, :class => @post_class
    
    @post_class.collection.remove
    @comment_class.collection.remove
  end
  
  should "default to nil" do
    @comment_class.new.post.nil?.should be_true
  end
  
  should "be able to replace the association" do
    post = @post_class.new(:name => 'mongomapper')
    comment = @comment_class.new(:name => 'Foo!', :post => post)
    comment.save.should be_true
    
    comment = comment.reload
    comment.post.should == post
    comment.post.nil?.should be_false
  end
  
  should "unset the association" do
    post = @post_class.new(:name => 'mongomapper')
    comment = @comment_class.new(:name => 'Foo!', :post => post)
    comment.save.should be_true
    
    comment = comment.reload
    comment.post = nil
    comment.post.nil?.should be_true
  end
  
  should "return nil if id set but document not found" do
    id = Mongo::ObjectID.new
    @comment_class.new(:name => 'Foo', :post_id => id).post.nil?.should be_true
  end
end