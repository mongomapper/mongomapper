require 'spec_helper'
require 'support/models'

describe "OneAsProxy" do
  before do
    @post_class  = Doc('Post')
    @author_class = Doc('Author')
  end

  it "should default to nil" do
    @post_class.one :author, :as => :authorable, :class => @author_class
    @post_class.new.author.nil?.should be_truthy
  end

  it "should return nil instead of a proxy" do
    @post_class.one :author, :as => :authorable, :class => @author_class
    nil.should === @post_class.new.author
  end

  it "should not define any keys" do
    count = @post_class.keys.length
    @post_class.one :author, :class => @author_class
    @post_class.keys.length.should == count
  end

  it "should allow assignment of associated document using a hash" do
    @post_class.one :author, :as => :authorable, :class => @author_class

    post = @post_class.new('author' => { 'name' => 'Frank' })
    post.author.name.should == 'Frank'

    post.save.should be_truthy
    post.reload

    post.author.name.should == 'Frank'
  end

  it "should only return a document with the correct type" do
    @post_class.one :author, :as => :authorable, :class => @author_class
    post = @post_class.create

    author = @author_class.create(:authorable_id => post.id, :authorable_type => "Nada")
    post.reload.author.should be_nil

    author = @author_class.create(:authorable_id => post.id, :authorable_type => "Post")
    post.reload.author.should == author
  end

  context "replacing the association" do
    context "with an object of the class" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class
        @post = @post_class.new
        @author = @author_class.new(:name => 'Frank')
      end

      it "should work" do
        @post.author = @author
        @post.reload

        @post.author.should == @author
        @post.author.nil?.should be_falsey

        new_author = @author_class.new(:name => 'Emily')
        @post.author = new_author
        @post.author.should == new_author
      end

      it "should generate a new proxy instead of modifying the existing one" do
        @post.author = @author
        @post.reload

        @post.author.should == @author
        @post.author.nil?.should be_falsey

        original_author = @post.author
        original_author.name.should == 'Frank'
        new_author = @author_class.new(:name => 'Emily')
        @post.author = new_author
        @post.author.should == new_author

        original_author.name.should == 'Frank'
      end

      it "should assign foreign key" do
        @post.author = @author
        @post.author.authorable_id.should == @post.id
      end

      it "should assign _type" do
        @post.author = @author
        @post.author.authorable_type.should == "Post"
      end
    end

    context "with a Hash" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class
        @post = @post_class.new
      end

      it "should convert to an object of the class and work" do
        @post.author = {'name' => 'Frank'}
        @post.reload

        @post.author.name.should == 'Frank'
        @post.author.nil?.should be_falsey

        @post.author = {'name' => 'Emily'}
        @post.author.name.should == 'Emily'
      end

      it "should assign foreign key" do
        @post.author = {'name' => 'Frank'}
        @post.author.authorable_id.should == @post.id
      end

      it "should assign _type" do
        @post.author = {'name' => 'Frank'}
        @post.author.authorable_type.should == "Post"
      end
    end

    context "with :dependent" do
      context "=> delete" do
        before do
          @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :delete

          @post = @post_class.create
          @author = @author_class.new
          @post.author = @author
        end

        it "should call delete on the existing document" do
          expect_any_instance_of(@author_class).to receive(:delete).once
          @post.author = @author_class.new
        end

        it "should remove the existing document from the database" do
          @post.author = @author_class.new
          lambda { @author.reload }.should raise_error(MongoMapper::DocumentNotFound)
        end

        it "should do nothing if it's the same document" do
          expect_any_instance_of(@author_class).to receive(:delete).never
          @post.author = @author
        end
      end

      context "=> destory" do
        before do
          @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :destroy

          @post = @post_class.create
          @author = @author_class.new
          @post.author = @author
        end

        it "should call destroy the existing document" do
          expect_any_instance_of(@author_class).to receive(:destroy).once
          @post.author = @author_class.new
        end

        it "should remove the existing document from the database" do
          @post.author = @author_class.new
          lambda { @author.reload }.should raise_error(MongoMapper::DocumentNotFound)
        end

        it "should do nothing if it's the same document" do
          expect_any_instance_of(@author_class).to receive(:destroy).never
          @post.author = @author
        end
      end

      context "=> nullify" do
        before do
          @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :nullify

          @post = @post_class.create
          @author = @author_class.new
          @post.author = @author
        end

        it "should nullify the existing document" do
          @author.reload
          @author.authorable_id.should == @post.id

          @post.author = @author_class.new

          @author.reload
          @author.authorable_id.should be_nil
        end

        it "should work when it's the same document" do
          old_author = @post.author
          @post.author = @author
          old_author.should == @post.author
        end

        it "should nullify _type" do
          @post.author = @author_class.new
          @author.reload
          @author.authorable_type.should be_nil
        end
      end

      context "unspecified" do
        before do
          @post_class.one :author, :as => :authorable, :class => @author_class

          @post = @post_class.create
          @author = @author_class.new
          @post.author = @author
        end

        it "should nullify the existing document" do
          @author.reload
          @author.authorable_id.should == @post.id

          @post.author = @author_class.new

          @author.reload
          @author.authorable_id.should be_nil
        end

        it "should nullify _type" do
          @post.author = @author_class.new
          @author.reload
          @author.authorable_type.should be_nil
        end
      end
    end

    context "with nil" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class

        @post = @post_class.new
        @author = @author_class.new(:name => 'Frank')
        @post.author = @author
      end

      it "should nullify the existing document" do
        @post.author = nil
        @author.reload
        @author.authorable_id.should be_nil
      end

      it "should set the target to nil" do
        @post.author = nil
        @post.author.should == nil
      end

      it "should nullify _type" do
        @post.author = nil
        @author.reload
        @author.authorable_type.should be_nil
      end
    end
  end

  it "should have boolean method for testing presence" do
    @post_class.one :author, :as => :authorable, :class => @author_class

    post = @post_class.new
    post.author?.should be_falsey

    post.author = @author_class.new(:name => 'Frank')
    post.author?.should be_truthy
  end

  it "should work with criteria" do
    @post_class.one :primary_author, :as => :authorable, :class => @author_class, :primary => true
    @post_class.one :author, :as => :authorable, :class => @author_class, :primary => false

    post = @post_class.create
    author = @author_class.create(:name => 'Frank', :primary => false, :authorable_id => post.id, :authorable_type => 'Post')
    primary = @author_class.create(:name => 'Bill', :primary => true, :authorable_id => post.id, :authorable_type => 'Post')
    post.reload
    post.author.should == author
    post.primary_author.should == primary
  end

  it "should unset the association" do
    @post_class.one :author, :as => :authorable, :class => @author_class
    post = @post_class.create
    author = @author_class.create
    post.update_attributes!(:author => author)
    post.reload
    post.author = nil
    post.author.nil?.should be_truthy
  end

  context "destroying parent with :dependent" do
    context "=> destroy" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :destroy

        @post = @post_class.create
        @author = @author_class.new
        @post.author = @author
      end

      it "should should call destroy on the associated documents" do
        expect_any_instance_of(@author_class).to receive(:destroy).once
        @post.destroy
      end

      it "should should remove the associated documents" do
        @author_class.count.should == 1
        @post.destroy
        @post.author.should == nil
        @author_class.count.should == 0
      end
    end

    context "=> delete" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :delete

        @post = @post_class.create
        @author = @author_class.new
        @post.author = @author
      end

      it "should should call delete the associated documents" do
        expect_any_instance_of(@author_class).to receive(:delete).once
        @post.destroy
      end

      it "should remove the associated documents" do
        @author_class.count.should == 1
        @post.destroy
        @post.author.should == nil
        @author_class.count.should == 0
      end
    end

    context "=> nullify" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :nullify

        @post = @post_class.create
        @author = @author_class.new
        @post.author = @author
      end

      it "should should nullify the relationship but not destroy the associated document" do
        @author_class.count.should == 1
        @post.destroy
        @post.author.should == nil
        @author_class.count.should == 1

        @author_class.first.should == @author
        @author.authorable_id.should == nil
      end

      it "should nullify _type" do
        @post.destroy
        @author.authorable_type.should be_nil
      end
    end

    context "unspecified" do
      before do
        @post_class.one :author, :as => :authorable, :class => @author_class

        @post = @post_class.create
        @author = @author_class.new
        @post.author = @author
      end

      it "should should nullify the relationship but not destroy the associated document" do
        @author_class.count.should == 1
        @post.destroy
        @post.author.should == nil
        @author_class.count.should == 1

        @author_class.first.should == @author
        @author.authorable_id.should == nil
      end

      it "should nullify _type" do
        @post.destroy
        @author.authorable_type.should be_nil
      end
    end
  end

  context "#build" do
    before do
      @post_class.one :author, :as => :authorable, :class => @author_class
      @post = @post_class.create
    end

    it "should be able to build with attributes" do
      author = @post.build_author(:name => 'John')
      @post.author.should be_instance_of(@author_class)
      @post.author.should be_new
      @post.author.name.should == 'John'
      @post.author.should == author
    end

    it "should assign foreign key" do
      @post.build_author
      @post.author.authorable_id.should == @post.id
    end

    it "should assign _type" do
        @post.build_author
        @post.author.authorable_type.should == 'Post'
    end
  end

  context "#create" do
     before do
      @post_class.one :author, :as => :authorable, :class => @author_class
      @post = @post_class.create
    end

    it "should be able to create" do
      author = @post.create_author(:name => 'John')
      @post.author.should be_instance_of(@author_class)
      @post.author.should_not be_new
      @post.author.name.should == 'John'
      @post.author.should == author
    end

    it "should assign foreign key" do
      @post.create_author
      @post.author.authorable_id.should == @post.id
    end

    it "should assign _type" do
      @post.create_author
      @post.author.authorable_type.should == 'Post'
    end
  end

  context "#create!" do
    before do
      @author_class.key :name, String, :required => true
      @post_class.one :author, :as => :authorable, :class => @author_class
      @post = @post_class.create
    end

    it "should raise exception if invalid" do
      expect { @post.create_author! }.to raise_error(MongoMapper::DocumentNotValid)
    end

    it "should work if valid" do
      author = @post.create_author!(:name => 'John')
      @post.author.should be_instance_of(@author_class)
      @post.author.should_not be_new
      @post.author.name.should == 'John'
      @post.author.should == author
    end

    it "should assign foreign key if valid" do
      @post.create_author!(:name => 'John')
      @post.author.authorable_id.should == @post.id
    end

    it "should assign _type if valid" do
      @post.create_author!(:name => 'John')
      @post.author.authorable_type.should == 'Post'
    end
  end

  context "namespaced foreign keys" do
    before do
      News::Paper.one :article, :as => 'articleable', :class_name => 'News::Article'
      News::Article.belongs_to :articleable, :polymorphic => true

      @paper = News::Paper.create
    end

    it "should work" do
      @paper.create_article
      @paper.article.class.should == News::Article
    end

    it "should properly infer the foreign key" do
      article = @paper.create_article
      article.should respond_to(:articleable_id)
      article.articleable_id.should == @paper.id
    end
  end
end