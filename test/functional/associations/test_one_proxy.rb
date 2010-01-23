require 'test_helper'

class OneProxyTest < Test::Unit::TestCase
  def setup
    @post_class = Doc('Post')
    @author_class = Doc do
      key :post_id, ObjectId
    end
  end
  
  should "default to nil" do
    @post_class.one :author, :class => @author_class
    @post_class.new.author.nil?.should be_true
  end
  
  should "send object id to target" do
    @post_class.one :author, :class => @author_class
    
    post = @post_class.new
    author = @author_class.new(:name => 'Frank')
    post.author = author
    author.save.should be_true
    post.save.should be_true
    
    post.author.object_id.should == post.author.target.object_id
  end
  
  should "be able to replace the association" do
    @post_class.one :author, :class => @author_class
    
    post = @post_class.new
    author = @author_class.new(:name => 'Frank')
    post.author = author
    post.reload
    
    post.author.should == author
    post.author.nil?.should be_false
    
    new_author = @author_class.new(:name => 'Emily')
    post.author = new_author
    post.author.should == new_author
  end
  
  should "have boolean method for testing presence" do
    @post_class.one :author, :class => @author_class
    
    post = @post_class.new
    post.author?.should be_false
    
    post.author = @author_class.new(:name => 'Frank')
    post.author?.should be_true
  end
  
  should "work with criteria" do
    @post_class.one :primary_author, :class => @author_class, :primary => true
    @post_class.one :author, :class => @author_class
    
    post = @post_class.create
    author = @author_class.create(:name => 'Frank', :primary => false, :post_id => post.id)
    primary = @author_class.create(:name => 'Bill', :primary => true, :post_id => post.id)
    post.author.should == author
    post.primary_author.should == primary
  end
  
  should "unset the association" do
    @post_class.one :author, :class => @author_class
    post = @post_class.new
    author = @author_class.new
    post.author = author
    post.reload
    
    post.author = nil
    post.author.nil?.should be_false
  end
  
  should "work with :dependent delete" do
    @post_class.one :author, :class => @author_class, :dependent => :delete
    
    post = @post_class.create
    author = @author_class.new
    post.author = author
    post.reload
    
    @author_class.any_instance.expects(:delete).once
    post.author = @author_class.new
  end
  
  should "work with :dependent destroy" do
    @post_class.one :author, :class => @author_class, :dependent => :destroy
    
    post = @post_class.create
    author = @author_class.new
    post.author = author
    post.reload
    
    @author_class.any_instance.expects(:destroy).once
    post.author = @author_class.new
  end
  
  should "work with :dependent nullify" do
    @post_class.one :author, :class => @author_class, :dependent => :nullify
    
    post = @post_class.create
    author = @author_class.new
    post.author = author
    post.reload
    
    post.author = @author_class.new
    
    author.reload
    author.post_id.should be_nil
  end

  should "be able to build" do
    @post_class.one :author, :class => @author_class
    
    post = @post_class.create
    author = post.author.build(:name => 'John')
    post.author.should be_instance_of(@author_class)
    post.author.should be_new
    post.author.name.should == 'John'
    post.author.should == author
    post.author.post_id.should == post.id
  end
  
  should "be able to create" do
    @post_class.one :author, :class => @author_class
    
    post = @post_class.create
    author = post.author.create(:name => 'John')
    post.author.should be_instance_of(@author_class)
    post.author.should_not be_new
    post.author.name.should == 'John'
    post.author.should == author
    post.author.post_id.should == post.id
  end
  
  context "#create!" do
    setup do
      @author_class.key :name, String, :required => true
      @post_class.one :author, :class => @author_class
    end
    
    should "raise exception if invalid" do
      post = @post_class.create
      assert_raises(MongoMapper::DocumentNotValid) do
        post.author.create!
      end
    end
    
    should "work if valid" do
      post = @post_class.create
      author = post.author.create!(:name => 'John')
      post.author.should be_instance_of(@author_class)
      post.author.should_not be_new
      post.author.name.should == 'John'
      post.author.should == author
      post.author.post_id.should == post.id
    end
  end
end