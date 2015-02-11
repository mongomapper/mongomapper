require 'spec_helper'

module CounterCacheFixtureModels
  class User
    include MongoMapper::Document

    key :posts_count, Integer, :default => 0

    has_many :posts,
             :class_name => "CounterCacheFixtureModels::Post"
  end

  class Post
    include MongoMapper::Document

    key :comments_count, Integer, :default => 0
    key :some_custom_comments_count, Integer, :default => 0
    key :commentable_count, Integer, :default => 0

    has_many :comments,
             :class_name => "CounterCacheFixtureModels::Comment"

    belongs_to :user,
               :counter_cache => true,
               :class_name => "CounterCacheFixtureModels::User"

    many :polymorphic_comments,
         :as => :commentable,
         :class_name => "CounterCacheFixtureModels::Comment"
  end

  class Article
    include MongoMapper::Document

    key :commentable_count, Integer, :default => 0

    many :polymorphic_comments,
         :as => :commentable,
         :class_name => "CounterCacheFixtureModels::Comment"
  end

  class Comment
    include MongoMapper::Document

    belongs_to :post,
               :counter_cache => true,
               :class_name => "CounterCacheFixtureModels::Post"

    belongs_to :commentable,
               :polymorphic => true,
               :counter_cache => :commentable_count
  end

  class CustomComment
    include MongoMapper::Document

    belongs_to :post,
               :counter_cache => :some_custom_comments_count,
               :class_name => "CounterCacheFixtureModels::Post"
  end
end

describe MongoMapper::Plugins::CounterCache do
  before do
    @post_class = CounterCacheFixtureModels::Post
    @comment_class = CounterCacheFixtureModels::Comment
    @user_class = CounterCacheFixtureModels::User
    @custom_comment_class = CounterCacheFixtureModels::CustomComment
  end

  it "should have a key with posts_count defaulting to 0" do
    @post_class.new.comments_count.should == 0
  end

  it "should update the count when a new object is created" do
    post = @post_class.new
    comment = @comment_class.new

    post.save!

    comment.post = post
    comment.save!

    post.reload
    post.comments_count.should == 1

    second_comment = @comment_class.new
    second_comment.post = post
    second_comment.save!

    post.reload
    post.comments_count.should == 2
  end

  it "should decrease the count by one when an object is destroyed" do
    post = @post_class.new
    comment = @comment_class.new

    post.save!

    comment.post = post
    comment.save!

    post.reload
    post.comments_count.should == 1

    comment.destroy
    post.reload
    post.comments_count.should == 0
  end

  it "should use the correct association name" do
    @user = @user_class.new
    @post = @post_class.new

    @user.save!
    @post.user = @user
    @post.save!

    @user.reload
    @user.posts_count.should == 1
  end

  it "should be able to use a custom field name" do
    @post = @post_class.new
    @custom_comment = @custom_comment_class.new

    @post.save!
    @custom_comment.post = @post
    @custom_comment.save!

    @post.reload
    @post.some_custom_comments_count.should == 1
  end

  it "should thrown an error if there is no association" do
    lambda {
      CounterCacheFixtureModels.module_eval do
        class CommentWithInvalidAssociation
          include MongoMapper::Document

          belongs_to :post,
                     :class_name => "CounterCacheFixtureModels::Post"

          counter_cache :foo
        end
      end
    }.should raise_error(MongoMapper::Plugins::CounterCache::InvalidCounterCacheError, "You must define an association with name `foo' on model CommentWithInvalidAssociation")
  end

  it "should thown a sensible error if the field is not defined on the target object" do
    lambda {
      CounterCacheFixtureModels.module_eval do
        class CommentWithBadRefenceField
          include MongoMapper::Document

          belongs_to :post,
                     :class_name => "CounterCacheFixtureModels::Post"

          counter_cache :post, :field => :invalid_field
        end
      end
    }.should raise_error(MongoMapper::Plugins::CounterCache::InvalidCounterCacheError, "Missing `key :invalid_field, Integer, :default => 0' on model CounterCacheFixtureModels::Post")
  end

  describe "with polymorphic associations" do
    before do
      @article = CounterCacheFixtureModels::Article.new
      @comment = CounterCacheFixtureModels::Comment.new
      @comment.commentable = @article
    end

    it "should update the counter cache on save" do
      expect {
        @comment.save!
        @article.reload
      }.to change(@article, :commentable_count).by(1)
    end

    it "should increment with a second object" do
      @comment.save!

      expect {
        second_comment = CounterCacheFixtureModels::Comment.new
        second_comment.commentable = @article
        second_comment.save!
        @article.reload
      }.to change(@article, :commentable_count).by(1)
    end

    it "should decrement the counter cache on destroy" do
      @comment.save!

      expect {
        @comment.destroy
        @article.reload
      }.to change(@article, :commentable_count).by(-1)
    end

    it "should increment with a different type of object" do
      @comment.save!

      expect {
        second_comment = CounterCacheFixtureModels::Comment.new
        second_comment.commentable = @article
        second_comment.save!

        @article.reload
      }.to change(@article, :commentable_count).by(1)
    end

    describe "without a counter cache field" do
      before do
        @comment = CounterCacheFixtureModels::Comment.new
        @klass = Class.new do
          include MongoMapper::Document

          many :polymorphic_comments,
               :as => :commentable,
               :class_name => "CounterCacheFixtureModels::Comment"
        end

        @obj = @klass.new
      end

      it "should raise at save (runtime) if there is no counter cache field" do
        @comment.commentable = @obj

        expect {
          @comment.save!
        }.to raise_error(MongoMapper::Plugins::CounterCache::InvalidCounterCacheError)
      end
    end
  end
end
