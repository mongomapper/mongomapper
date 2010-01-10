require 'test_helper'

class StringIdCompatibilityTest < Test::Unit::TestCase
  def setup
    @note_class = EDoc do
      key :_id, String
    end
    
    @task_class = Doc do
      key :_id, String
      key :project_id, String
      belongs_to :project
    end
    
    @project_class = Doc do
      include MongoMapper::Document
      key :_id, String
    end
    
    @task_class.belongs_to :project, :class => @project_class
    @project_class.many :notes, :class => @note_class
    @project_class.many :tasks, :class => @task_class, :foreign_key => 'project_id', :order => :position.asc
  end
  
  should "assign correct _id for documents" do
    project = @project_class.create
    project._id.should == project.id
    project._id.should be_instance_of(String)
    project.id.size.should == 24
    lambda {
      Mongo::ObjectID.from_string(project.id)
    }.should_not raise_error
  end
  
  should "assign correct _id for embedded documents" do
    note = @note_class.new
    note.id.should == note._id
    note.id.size.should == 24
  end
  
  should "find records" do
    project = @project_class.create
    @project_class.find(project.id).should == project
  end
    
  should "save embedded docs" do
    n1 = @note_class.new
    n2 = @note_class.new
    n3 = @note_class.new
    project = @project_class.create(:notes => [n1, n2, n3])
    
    project = project.reload
    project.notes.size.should == 3
    project.notes.should == [n1, n2, n3]
  end
  
  should "be able to associate records" do
    t1 = @task_class.new(:body => 'First task', :position => 1)
    t2 = @task_class.new(:body => 'Second task', :position => 2)
    t3 = @task_class.new(:body => 'Third task', :position => 3)
    project = @project_class.create(:name => 'MM', :tasks => [t1, t2, t3])
    
    project = project.reload
    project.tasks.count.should == 3
    project.tasks.should == [t1, t2, t3]
  end
end