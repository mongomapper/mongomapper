require 'test_helper'
require 'models'

class BelongsToPolymorphicProxyTest < Test::Unit::TestCase
  def setup
    Status.collection.clear
    Project.collection.clear
  end
  
  should "default to nil" do
    status = Status.new
    status.target.nil?.should be_true
    status.target.inspect.should == "nil"
  end

  should "be able to replace the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.target = project
    status.save.should be_true

    from_db = Status.find(status.id)
    from_db.target.nil?.should be_false
    from_db.target_id.should == project.id
    from_db.target_type.should == "Project"
    from_db.target.name.should == "mongomapper"
  end

  should "unset the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.target = project
    status.save.should be_true

    from_db = Status.find(status.id)
    from_db.target = nil
    from_db.target_type.nil?.should be_true
    from_db.target_id.nil?.should be_true
    from_db.target.nil?.should be_true
  end
  
  context "association id set but document not found" do
    setup do
      @status = Status.new
      project = Project.new(:name => "mongomapper")
      @status.target = project
      @status.save.should be_true
      project.destroy
    end

    should "return nil instead of raising error" do
      @status.target.nil?.should be_true
    end
  end
end