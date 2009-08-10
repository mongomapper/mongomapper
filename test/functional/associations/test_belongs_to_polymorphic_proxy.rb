require 'test_helper'
require 'models'

class BelongsToPolymorphicProxyTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end
  
  should "default to nil" do
    status = Status.new
    status.target.should be_nil
  end

  should "be able to replace the association" do
    status = Status.new
    project = Project.new(:name => "mongomapper")
    status.target = project
    status.save.should be_true

    from_db = Status.find(status.id)
    from_db.target.should_not be_nil
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
    from_db.target_type.should be_nil
    from_db.target_id.should be_nil
    from_db.target.should be_nil
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
      @status.target.should be_nil
    end
  end
end