require 'test_helper'

class Comment
  include MongoMapper::Document
  
  key :name, String
  key :body, String
  
  attr_accessor :callers
  before_validation :record_callers

  def after_validation
    record_callers
  end

  def record_callers
    callers << self.class if callers
  end
end

class Article
  include MongoMapper::Document
  
  key :title, String
  key :body, String
end

class CommentObserver < MongoMapper::Observer
  attr_accessor :callers

  def after_validation(model)
    callers << self.class if callers
  end
end

class AuditObserver < MongoMapper::Observer
  observe Article, Comment
  attr_reader :document
  
  def after_validation(document)
    @document = document
  end
end

class GlobalObserver < MongoMapper::Observer
  observe Article, Comment
  attr_reader :document
  
  def before_save(document)
    @document = document
  end
end

class NonAutomaticObserver < MongoMapper::Observer
  observe Comment
  attr_reader :comment
  
  def after_validation(comment)
    @comment = comment
  end
end

class ObserverTest < Test::Unit::TestCase  
  should "fire model callbacks before observer" do
    callers = []
    comment = Comment.new
    comment.callers = callers

    CommentObserver.instance.callers = callers

    comment.valid?
    callers.should == [Comment, Comment, CommentObserver]
  end
  
  should "automatically observe model based on name when possible" do
    CommentObserver.observed_class.should == Comment
  end
  
  should "be able to observe other models using observe" do
    obs = NonAutomaticObserver.instance
    comment = Comment.new(:name => 'John Nunemaker', :body => 'is awesome')
    comment.valid?
    obs.comment.name.should == 'John Nunemaker'
    obs.comment.body.should == 'is awesome'
  end
  
  should "be able to observe multiple models" do
    obs = AuditObserver.instance
    comment = Comment.new(:name => 'Steve Smith', :body => 'is awesome')
    comment.valid?
    
    obs.document.name.should == 'Steve Smith'
    obs.document.body.should == 'is awesome'
    
    article = Article.new(:title => 'Ordered List Is Awesome', :body => 'Learn to accept it!')
    article.valid?
    
    obs.document.title.should == 'Ordered List Is Awesome'
    obs.document.body.should == 'Learn to accept it!'
  end
end