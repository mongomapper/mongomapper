require 'spec_helper'

describe "OneEmbeddedProxy" do
  before do
    @post_class = Doc('Post') do
      key :title, String
    end
    @author_class = EDoc('Author') do
      key :name, String
      embedded_in :post
    end
  end

  it "should default to nil" do
    @post_class.one :author, :class => @author_class
    @post_class.new.author.should be_nil
  end

  it "should be able to build" do
    @post_class.one :author, :class => @author_class

    post = @post_class.create
    author = post.build_author(:name => "John")
    post.author.should be_instance_of(@author_class)
    post.author.should be_new
    post.author.name.should == 'John'
    post.author.should == author
    post.author.post.should == post
  end

  it "should be able to replace the association" do
    @post_class.one :author, :class => @author_class

    post = @post_class.new
    author = @author_class.new(:name => 'Frank')
    post.author = author
    post.save
    post.reload

    post.author.should == author
    post.author.nil?.should be_falsey

    new_author = @author_class.new(:name => 'Emily')
    post.author = new_author
    post.author.should == new_author
  end

  it "should not have problem loading root document if embedded one is nil" do
    @post_class.one :author, :class => @author_class
    post = @post_class.create

    lambda {
      @post_class.find(post.id)
    }.should_not raise_error
  end

  it "should load the parent and root documents for nested embedded documents" do
    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
    @author_class.one :address, :class => @address_class
    @post_class.one :author, :class => @author_class

    post = @post_class.create(:title => 'Post Title', :author => { :name => 'Frank', :address => { :city => 'Boston', :state => 'MA' } })

    post.author.address._parent_document.should == post.author
    post.author.address._root_document.should == post
  end

  it "should have boolean method for testing presence" do
    @post_class.one :author, :class => @author_class

    post = @post_class.new
    post.author?.should be_falsey

    post.author = @author_class.new(:name => 'Frank')
    post.author?.should be_truthy
  end

  it "should initialize id for nested embedded document created from hash" do
    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
    @author_class.one(:address, :class => @address_class)
    @post_class.one(:author, :class => @author_class)

    post = @post_class.create(:title => 'Post Title', :author => {
      :name => 'Frank',
      :address => {
        :city => 'Boston',
        :state => 'MA'
      }
    })

    post.author.address.id.should_not be_nil
  end

end
