require 'test_helper'
require 'models'

class OneEmbeddedPolymorhpicProxyTest < Test::Unit::TestCase
  def setup
    @post_class = Doc('Post') do
      key :title, String
    end
  end

  should "default to nil" do
    @post_class.one :author, :polymorphic => true, :class => Robot
    @post_class.new.author.should be_nil
  end

  should "return nil instead of a proxy" do
    @post_class.one :author, :polymorphic => true, :class => Robot
    nil.should === @post_class.new.author
  end

  should "be able to build" do
    @post_class.one :author, :polymorphic => true, :class => Robot
    post = @post_class.create
    author = post.build_author(:serial_number => "1B")
    post.author.should be_instance_of(Robot)
    post.author.should be_new
    post.author.serial_number.should == '1B'
    post.author.should == author
    post.author.post.should == post
  end

  should "allow assignment of associated document using a hash" do
    @post_class.one :author, :polymorphic => :true, :class => Robot
  
    post = @post_class.new('author' => { 'name' => 'Frank', '_type' => 'Human' })
    post.author.name.should == 'Frank'
    post.author.class.should == Human
  
    post.save.should be_true
    post.reload
  
    post.author.name.should == 'Frank'
    post.author.class.should == Human
  end

  context "replacing the association" do
    context "with an object" do
      setup do
        @post_class.one :author, :polymorphic => true, :class => Robot
        @post = @post_class.create
        @human = Human.new(:name => 'Frank')
      end

      should "work" do
        @post.author = @human
        @post.save
        @post.reload

        @post.author.should == @human
        @post.author.nil?.should be_false
        @post.author.class.should == Human

        new_human = Human.new(:name => 'Emily')
        @post.author = new_human
        @post.author.should == new_human
      end

      should "generate a new proxy instead of modifying the existing one" do
        @post.author = @human
        @post.save
        @post.reload

        @post.author.should == @human
        @post.author.nil?.should be_false

        original_author = @post.author
        original_author.name.should == 'Frank'
        new_human = Human.new(:name => 'Emily')
        @post.author = new_human
        @post.author.should == new_human

        original_author.name.should == 'Frank'
      end

      should "assign _type" do
        @post.author = @human
        @post.author._type.should == "Human"
      end
    end

    context "with a Hash" do
      setup do
        @post_class.one :author, :polymorphic => true, :class => Robot
        @post = @post_class.create
      end

      should "convert to an object of the class and work" do
        @post.author = {'serial_number' => '1B'}
        @post.save
        @post.reload

        @post.author.serial_number.should == '1B'
        @post.author.nil?.should be_false

        @post.author = {'serial_number' => '2C'}
        @post.author.serial_number.should == '2C'
      end

      should "convert to an object of _type if given" do
        @post.author = {'name' => 'Frank', '_type' => 'Human'}
        @post.author.name.should == 'Frank'
        @post.author.class.should == Human
        @post.save
        @post.reload

        @post.author.name.should == 'Frank'
        @post.author.class.should == Human
      end

      should "assign _type" do
        @post.author = {'name' => 'Frank', '_type' => 'Human'}
        @post.save
        @post.reload
        @post.author._type.should == "Human"
      end
    end
  end

  should "unset the association" do
    @post_class.one :author, :polymorphic => true, :class => Robot
    post = @post_class.create
    human = Human.new
    post.update_attributes!(:author => human)
    post.reload
    post.author = nil
    post.author.should == nil
  end

  should "set modularized associated models correctly" do
    @post_class.one :author, :polymorphic => true, :class => Robot

    post = @post_class.new('author' => {'_type' => 'TrModels::Ambulance', 'license_plate' => 'GGG123', 'icu' => true})

    post.author.class.should == TrModels::Ambulance
    post.author.license_plate.should == 'GGG123'
    post.author.icu.should be_true
    post.save.should be_true

    post = post.reload
    post.author.class.should == TrModels::Ambulance
    post.author.license_plate.should == 'GGG123'
    post.author.icu.should be_true
  end

  should "not have problem loading root document if embedded one is nil" do
    @post_class.one :author, :polymorphic => true, :class => Robot
    post = @post_class.create

    lambda {
      @post_class.find(post.id)
    }.should_not raise_error
  end

  should "load the parent and root documents for nested embedded documents" do
    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
    @author_class = EDoc('EmbeddedAuthor')
    @author_class.one :address, :polymorphic => true, :class => @address_class
    @post_class.one :author, :polymorphic => true, :class => @author_class
  
    post = @post_class.create(:title => 'Post Title', :author => { :name => 'Frank', :address => { :city => 'Boston', :state => 'MA' } })
  
    post.author.address._parent_document.should == post.author
    post.author.address._root_document.should == post
  end
  
  should "have boolean method for testing presence" do
    @post_class.one :author, :polymorphic => true, :class => Robot
  
    post = @post_class.new
    post.author?.should be_false
  
    post.author = Human.new(:name => 'Frank')
    post.author?.should be_true
  end

  should "initialize id for nested embedded document created from hash" do
    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
    @author_class = EDoc('EmbeddedAuthor')
    @author_class.one :address, :polymorphic => true, :class => @address_class
    @post_class.one :author, :polymorphic => true, :class => @author_class  

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
