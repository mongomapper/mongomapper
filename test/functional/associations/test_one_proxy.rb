require 'test_helper'
require 'models'

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

  should "return nil instead of a proxy" do
    @post_class.one :author, :class => @author_class
    nil.should === @post_class.new.author
  end

  should "allow assignment of associated document using a hash" do
    @post_class.one :author, :class => @author_class

    post = @post_class.new('author' => { 'name' => 'Frank' })
    post.author.name.should == 'Frank'

    post.save.should be_true
    post.reload

    post.author.name.should == 'Frank'
  end

  context "replacing the association" do
    context "with an object of the class" do
      should "work" do
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

      should "generate a new proxy instead of modifying the existing one" do
        @post_class.one :author, :class => @author_class

        post = @post_class.new
        author = @author_class.new(:name => 'Frank')
        post.author = author
        post.reload

        post.author.should == author
        post.author.nil?.should be_false

        original_author = post.author
        original_author.name.should == 'Frank'
        new_author = @author_class.new(:name => 'Emily')
        post.author = new_author
        post.author.should == new_author

        original_author.name.should == 'Frank'
      end
    end

    context "with a Hash" do
      should "convert to an object of the class and work" do
        @post_class.one :author, :class => @author_class

        post = @post_class.new
        post.author = {'name' => 'Frank'}
        post.reload

        post.author.name.should == 'Frank'
        post.author.nil?.should be_false

        post.author = {'name' => 'Emily'}
        post.author.name.should == 'Emily'
      end
    end
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
    @post_class.one :author, :class => @author_class, :primary => false

    post = @post_class.create
    author = @author_class.create(:name => 'Frank', :primary => false, :post_id => post.id)
    primary = @author_class.create(:name => 'Bill', :primary => true, :post_id => post.id)
    post.reload
    post.author.should == author
    post.primary_author.should == primary
  end
  
  # concerning the following two tests:
  # when parent was being assigned to child, it was first saved, which autosaved its currently nil child 
  # that gave it a "loaded" nil proxy, causing parent.child.parent to be nil
  # these tests are to avoid a regression
  should "properly assign the associated object when assigning the association with create" do
    child_class = Doc('Child')
    parent_class = Doc('Parent')
    
    parent_class.one :child, :class => child_class
    child_class.belongs_to :parent, :class => parent_class
    
    parent = parent_class.create(:child => child_class.create)
    parent.child.parent.should == parent
  end
  
  should "properly assign the associated object when assigning the association with new" do
    child_class = Doc('Child')
    parent_class = Doc('Parent')
    
    parent_class.one :child, :class => child_class
    child_class.belongs_to :parent, :class => parent_class
    
    parent = parent_class.create(:child => child_class.create)
    parent.child.parent.should == parent
  end

  should "unset the association" do
    @post_class.one :author, :class => @author_class
    post = @post_class.create
    author = @author_class.create
    post.update_attributes!(:author => author)
    post.reload
    post.author = nil
    post.author.nil?.should be_true
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
    author = post.build_author(:name => 'John')
    post.author.should be_instance_of(@author_class)
    post.author.should be_new
    post.author.name.should == 'John'
    post.author.should == author
    post.author.post_id.should == post.id
  end

  should "be able to create" do
    @post_class.one :author, :class => @author_class

    post = @post_class.create
    author = post.create_author(:name => 'John')
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
        post.create_author!
      end
    end

    should "work if valid" do
      post = @post_class.create
      author = post.create_author!(:name => 'John')
      post.author.should be_instance_of(@author_class)
      post.author.should_not be_new
      post.author.name.should == 'John'
      post.author.should == author
      post.author.post_id.should == post.id
    end
  end

  context "namespaced foreign keys" do
    setup do
      News::Paper.one :article, :class_name => 'News::Article'
      News::Article.belongs_to :paper, :class_name => 'News::Paper'

      @paper = News::Paper.create
    end

    should "properly infer the foreign key" do
      article = @paper.create_article
      article.should respond_to(:paper_id)
      article.paper_id.should == @paper.id
    end
  end
end