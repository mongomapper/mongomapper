require 'test_helper'
require 'models'

class BelongsToProxyTest < Test::Unit::TestCase
  def setup
    Status.collection.clear
    Project.collection.clear
  end
  
  should "default to nil" do
    status = Status.new
    status.project.nil?.should == true
    status.project.inspect.should == 'nil'
  end
  
  should "be able to replace the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.project = project
    status.save.should be_true
    
    from_db = Status.find(status.id)
    from_db.project.nil?.should be_false
    from_db.project.name.should == "mongomapper"
  end
  
  should "unset the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.project = project
    status.save.should be_true
    
    from_db = Status.find(status.id)
    from_db.project = nil
    from_db.project.nil?.should be_true
    from_db.project.inspect.should == 'nil'
  end
  
  context "association id set but document not found" do
    setup do
      @status = Status.new(:name => 'Foo', :project_id => '1234')
    end

    should "return nil instead of raising error" do
      @status.project.nil?.should be_true
      @status.project.inspect.should == 'nil'
    end
  end
end