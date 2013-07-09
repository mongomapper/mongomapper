require 'spec_helper'

describe "OneProxy" do
  let(:post_class) { Doc('Post') }
  let(:author_class) {
    Doc do
      key :name
      key :post_id, ObjectId
    end
  }

  it "should default to nil" do
    post_class.one :author, :class => author_class
    post_class.new.author.nil?.should be_true
  end

  it "should return nil instead of a proxy" do
    post_class.one :author, :class => author_class
    nil.should === post_class.new.author
  end

  it "should allow assignment of associated document using a hash" do
    post_class.one :author, :class => author_class

    post = post_class.new('author' => { 'name' => 'Frank' })
    post.author.name.should == 'Frank'

    post.save.should be_true
    post.reload

    post.author.name.should == 'Frank'
  end

  context "replacing the association" do
    context "with an object of the class" do
      it "should work" do
        post_class.one :author, :class => author_class

        post = post_class.new
        author = author_class.new(:name => 'Frank')
        post.author = author
        post.save
        post.reload

        post.author.should == author
        post.author.nil?.should be_false

        new_author = author_class.new(:name => 'Emily')
        post.author = new_author
        post.author.should == new_author
      end

      it "should generate a new proxy instead of modifying the existing one" do
        post_class.one :author, :class => author_class

        post = post_class.new
        author = author_class.new(:name => 'Frank')
        post.author = author
        post.save
        post.reload

        post.author.should == author
        post.author.nil?.should be_false

        original_author = post.author
        original_author.name.should == 'Frank'
        new_author = author_class.new(:name => 'Emily')
        post.author = new_author
        post.author.should == new_author

        original_author.name.should == 'Frank'
      end
    end

    context "with a Hash" do
      it "should convert to an object of the class and work" do
        post_class.one :author, :class => author_class

        post = post_class.new
        post.author = {'name' => 'Frank'}
        post.save
        post.reload

        post.author.name.should == 'Frank'
        post.author.nil?.should be_false

        post.author = {'name' => 'Emily'}
        post.author.name.should == 'Emily'
      end
    end

    context "with :dependent" do
      context "unspecified" do
        it "should nullify the existing document" do
          post_class.one :author, :class => author_class

          post = post_class.create
          author = author_class.new
          post.author = author
          post.save
          author.reload
          author.post_id.should == post.id

          post.author = author_class.new
          post.save

          author.reload
          author.post_id.should be_nil
        end
      end
    end

    context "with nil" do
      before do
        post_class.one :author, :class => author_class

        @post = post_class.new
        @author = author_class.new(:name => 'Frank')
        @post.author = @author
        @post.save
      end

      it "should nullify the existing document" do
        @post.author = nil
        @post.save
        @author.reload
        @author.post_id.should be_nil
      end

      it "should set the target to nil" do
        @post.author = nil
        @post.author.should == nil
      end
    end
  end

  it "should have boolean method for testing presence" do
    post_class.one :author, :class => author_class

    post = post_class.new
    post.author?.should be_false

    post.author = author_class.new(:name => 'Frank')
    post.author?.should be_true
  end

  it "should work with criteria" do
    post_class.one :primary_author, :class => author_class, :primary => true
    post_class.one :author, :class => author_class, :primary => false

    post = post_class.create
    author = author_class.create(:name => 'Frank', :primary => false, :post_id => post.id)
    primary = author_class.create(:name => 'Bill', :primary => true, :post_id => post.id)
    post.reload
    post.author.should == author
    post.primary_author.should == primary
  end

  it "should unset the association" do
    post_class.one :author, :class => author_class
    post = post_class.create
    author = author_class.create
    post.update_attributes!(:author => author)
    post.reload
    post.author = nil
    post.author.nil?.should be_true
  end

  context "destroying parent with :dependent" do
    context "=> destroy" do
      before do
        post_class.one :author, :class => author_class, :dependent => :destroy

        @post = post_class.create
        @author = author_class.new
        @post.author = @author
        @post.save
      end

      it "should should call destroy on the associated documents" do
        author_class.any_instance.should_receive(:destroy).once
        @post.destroy
      end

      it "should should remove the associated documents" do
        author_class.count.should == 1
        @post.destroy
        @post.author.should == nil
        author_class.count.should == 0
      end
    end

    context "=> :delete" do
      before do
        post_class.one :author, :class => author_class, :dependent => :delete

        @post = post_class.create
        @author = author_class.new
        @post.author = @author
        @post.save
      end

      it "should call delete the associated documents" do
        author_class.any_instance.should_receive(:delete)
        @post.destroy
      end

      it "should remove the associated documents" do
        expect { @post.destroy }.to change { author_class.count }.by( -1 )
        @post.author.should == nil
      end
    end

    context "=> nullify" do
      it "should should nullify the relationship but not destroy the associated document" do
        post_class.one :author, :class => author_class, :dependent => :nullify

        post = post_class.create
        author = author_class.new
        post.author = author
        post.save

        author_class.count.should == 1
        post.destroy
        post.author.should == nil
        author_class.count.should == 1

        author_class.first.should == author
        author.post_id.should == nil
      end
    end

    context "unspecified" do
      it "should should nullify the relationship but not destroy the associated document" do
        post_class.one :author, :class => author_class

        post = post_class.create
        author = author_class.new
        post.author = author
        post.save

        author_class.count.should == 1
        post.destroy
        post.author.should == nil
        author_class.count.should == 1

        author_class.first.should == author
        author.post_id.should == nil
      end
    end
  end

  context "when building associations" do
    before do
      post_class.one :author, :class => author_class
    end
    let(:post) { post_class.create }

    context "#build" do
      it "should work" do
        author = post.build_author(:name => 'John')
        post.author.should be_instance_of(author_class)
        post.author.should be_new
        post.author.name.should == 'John'
        post.author.should == author
        post.author.post_id.should == post.id
      end

      it "should allow a block" do
        author = post.build_author do |doc|
          doc.name = "John"
        end
        author.name.should == "John"
      end
    end

    context "#create" do
      it "should work" do
        author = post.create_author(:name => 'John')
        post.author.should be_instance_of(author_class)
        post.author.should_not be_new
        post.author.name.should == 'John'
        post.author.should == author
        post.author.post_id.should == post.id
      end

      it "should allow a block" do
        author = post.create_author do |doc|
          doc.name = "John"
        end
        author.name.should == "John"
      end
    end


    context "#create!" do
      before do
        author_class.key :name, String, :required => true
      end

      it "should raise exception if invalid" do
        expect {
          post.create_author!
        }.to raise_error(MongoMapper::DocumentNotValid)
      end

      it "should work if valid" do
        author = post.create_author!(:name => 'John')
        post.author.should be_instance_of(author_class)
        post.author.should_not be_new
        post.author.name.should == 'John'
        post.author.should == author
        post.author.post_id.should == post.id
      end

      it "should accept a block" do
        author = post.create_author! do |doc|
          doc.name = "John"
        end
        author.name.should == "John"
      end
    end
  end

  context "namespaced foreign keys" do
    before do |example|
      module OneProxySpec; end
      OneProxySpec::Paper = Class.new(News::Paper)
      OneProxySpec::Article = Class.new(News::Article)
      OneProxySpec::Paper.one :article, :class_name => 'OneProxySpec::Article'
      OneProxySpec::Article.belongs_to :paper, :class_name => 'OneProxySpec::Paper'

      @paper = OneProxySpec::Paper.create
    end

    it "should properly infer the foreign key" do
      article = @paper.create_article
      article.should respond_to(:paper_id)
      article.paper_id.should == @paper.id
    end
  end
end
