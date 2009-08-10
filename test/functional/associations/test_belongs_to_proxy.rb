require 'test_helper'
require 'models'

class BelongsToProxyTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end
  
  should "default to nil" do
    status = Status.new
    status.project.should be_nil
  end
  
  should "be able to replace the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.project = project
    status.save.should be_true
    
    from_db = Status.find(status.id)
    from_db.project.should_not be_nil
    from_db.project.name.should == "mongomapper"
  end
  
  should "unset the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.project = project
    status.save.should be_true
    
    from_db = Status.find(status.id)
    from_db.project = nil
    from_db.project.should be_nil
  end
  
  context "association id set but document not found" do
    setup do
      @status = Status.new(:name => 'Foo', :project_id => '1234')
    end

    should "return nil instead of raising error" do
      @status.project.should be_nil
    end
  end
end