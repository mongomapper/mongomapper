require 'test_helper'
require 'models'

class BelongsToProxyTest < Test::Unit::TestCase
  def setup
    @post_class = Doc()
    @comment_class = Doc do
      key :post_id, String
    end

    @comment_class.belongs_to :post, :class => @post_class
  end

  should "default to nil" do
    @comment_class.new.post.nil?.should be_true
  end

  should "return nil instead of a proxy" do
    nil.should === @comment_class.new.post
  end

  should "have boolean presence method" do
    comment = @comment_class.new(:name => 'Foo!')
    comment.post?.should be_false

    comment.post = @post_class.new(:name => 'mongomapper')
    comment.post?.should be_true
  end

  should "allow overriding association methods" do
    @comment_class.class_eval do
      def post?
        super
      end
    end

    instance = @comment_class.new
    instance.post?.should be_false
    instance.post = @post_class.new
    instance.post?.should be_true
  end

  should "be able to replace the association" do
    post = @post_class.new(:name => 'mongomapper')
    comment = @comment_class.new(:name => 'Foo!', :post => post)
    comment.save.should be_true

    comment = comment.reload
    comment.post.should == post
    comment.post.nil?.should be_false
  end
  
  should "not reload the association when replacing" do
    post = @post_class.new(:name => 'mongomapper')
    comment = @comment_class.new(:name => 'Foo!', :post => post)
    comment.post.proxy_target.object_id.should == post.object_id
  end
  
  should "work (create!)" do
    account_class = Doc()
    agent_class = Doc() do
      one :account, :class => account_class
    end
    account_class.belongs_to :agent, :class => agent_class
    
    account = account_class.create!(:agent => agent_class.create!)
    
    agent = account.agent
    # debugger
    agent.account
    agent.account.should == account
  end

  should "work the other way (create!)" do
    account_class = Doc()
    agent_class = Doc() do
      one :account, :class => account_class
    end
    account_class.belongs_to :agent, :class => agent_class
    
    agent = agent_class.create!(:account => account_class.create!)
    agent.account.agent.should == agent
  end
  
  should "work (new)" do
    account_class = Doc()
    agent_class = Doc() do
      one :account, :class => account_class
    end
    account_class.belongs_to :agent, :class => agent_class
    
    account = account_class.create!(:agent => agent_class.new)
    account.agent.account.should == account
  end

  should "work (new new)" do
    account_class = Doc()
    agent_class = Doc() do
      one :account, :class => account_class
    end
    account_class.belongs_to :agent, :class => agent_class
    
    account = account_class.new(:agent => agent_class.new)
    account.agent.account.should == account
  end

  should "generate a new proxy when replacing the association" do
    post1 = @post_class.create(:name => 'post1')
    post2 = @post_class.create(:name => 'post2')

    comment = @comment_class.new(:name => 'Foo!', :post => post1)
    comment.save.should be_true


    comment = comment.reload
    comment.post.should == post1
    comment.post.nil?.should be_false

    original_post = comment.post
    original_post.name.should == 'post1'

    comment.post = post2
    comment.post.name.should == 'post2'
    original_post.name.should == 'post1'
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
    id = BSON::ObjectId.new
    @comment_class.new(:name => 'Foo', :post_id => id).post.nil?.should be_true
  end

  context ":dependent" do
    setup do
      # FIXME: make use of already defined models
      class ::Property
        include MongoMapper::Document
      end
      Property.collection.remove

      class ::Thing
        include MongoMapper::Document
        key :name, String
      end
      Thing.collection.remove
    end

    teardown do
      Object.send :remove_const, 'Property' if defined?(::Property)
      Object.send :remove_const, 'Thing' if defined?(::Thing)
    end

    context "=> destroy" do
      setup do
        Property.key :thing_id, ObjectId
        Property.belongs_to :thing, :dependent => :destroy
        Thing.many :properties

        @thing = Thing.create(:name => "Tree")
        @property1 = Property.create
        @property2 = Property.create
        @property3 = Property.create
        @thing.properties << @property1
        @thing.properties << @property2
        @thing.properties << @property3
      end

      should "not execute on a belongs_to association" do
        Thing.count.should == 1
        @property1.destroy
        Thing.count.should == 1
      end
    end
  end
end