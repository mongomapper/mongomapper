require 'test_helper'
require 'models'

class ManyProxyTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end
  
  should "default reader to empty array" do
    project = Project.new
    project.statuses.should == []
  end

  should "allow adding to association like it was an array" do
    project = Project.new
    project.statuses << Status.new
    project.statuses.push Status.new
    project.statuses.size.should == 2
  end

  should "store the association" do
    project = Project.new
    project.statuses = [Status.new("name" => "ready")]
    project.save.should be_true

    from_db = Project.find(project.id)
    from_db.statuses.size.should == 1
    from_db.statuses[0].name.should == "ready"
  end
  
  context "Finding scoped to association" do
    setup do
      @project1          = Project.new(:name => 'Project 1')
      @brand_new         = Status.create(:name => 'New')
      @complete          = Status.create(:name => 'Complete')
      @project1.statuses = [@brand_new, @complete]
      @project1.save
      
      @project2          = Project.create(:name => 'Project 2')
      @in_progress       = Status.create(:name => 'In Progress')
      @archived          = Status.create(:name => 'Archived')
      @another_complete  = Status.create(:name => 'Complete')
      @project2.statuses = [@in_progress, @archived, @another_complete]
      @project2.save
    end
    
    context "with :all" do
      should "work" do
        @project1.statuses.find(:all).should == [@brand_new, @complete]
      end
      
      should "work with conditions" do
        statuses = @project1.statuses.find(:all, :conditions => {'name' => 'Complete'})
        statuses.should == [@complete]
      end
      
      should "work with order" do
        statuses = @project1.statuses.find(:all, :order => 'name asc')
        statuses.should == [@complete, @brand_new]
      end
    end

    context "with #all" do
      should "work" do
        @project1.statuses.all.should == [@brand_new, @complete]
      end
      
      should "work with conditions" do
        statuses = @project1.statuses.all(:conditions => {'name' => 'Complete'})
        statuses.should == [@complete]
      end
      
      should "work with order" do
        statuses = @project1.statuses.all(:order => 'name asc')
        statuses.should == [@complete, @brand_new]
      end
    end
    
    context "with :first" do
      should "work" do
        @project1.statuses.find(:first).should == @brand_new
      end
      
      should "work with conditions" do
        status = @project1.statuses.find(:first, :conditions => {:name => 'Complete'})
        status.should == @complete
      end
    end
    
    context "with #first" do
      should "work" do
        @project1.statuses.first.should == @brand_new
      end
      
      should "work with conditions" do
        status = @project1.statuses.first(:conditions => {:name => 'Complete'})
        status.should == @complete
      end
    end
    
    context "with :last" do
      should "work" do
        @project1.statuses.find(:last).should == @complete
      end
      
      should "work with conditions" do
        status = @project1.statuses.find(:last, :conditions => {:name => 'New'})
        status.should == @brand_new
      end
    end
    
    context "with #last" do
      should "work" do
        @project1.statuses.last.should == @complete
      end
      
      should "work with conditions" do
        status = @project1.statuses.last(:conditions => {:name => 'New'})
        status.should == @brand_new
      end
    end
    
    context "with one id" do
      should "work for id in association" do
        @project1.statuses.find(@complete.id).should == @complete
      end
      
      should "not work for id not in association" do
        lambda {
          @project1.statuses.find(@archived.id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end
    
    context "with multiple ids" do
      should "work for ids in association" do
        statuses = @project1.statuses.find(@brand_new.id, @complete.id)
        statuses.should == [@brand_new, @complete]
      end
      
      should "not work for ids not in association" do
        lambda {
          @project1.statuses.find(@brand_new.id, @complete.id, @archived.id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end
    
    context "with #paginate" do
      setup do
        @statuses = @project2.statuses.paginate(:per_page => 2, :page => 1)
      end
      
      should "return total pages" do
        @statuses.total_pages.should == 2
      end
      
      should "return total entries" do
        @statuses.total_entries.should == 3
      end
      
      should "return the subject" do
        @statuses.should == [@in_progress, @archived]
      end
    end
  end
end