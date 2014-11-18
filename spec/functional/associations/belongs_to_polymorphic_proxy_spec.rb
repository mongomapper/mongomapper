require 'spec_helper'


describe "BelongsToPolymorphicProxy" do
  before do
    Status.collection.remove
    Project.collection.remove
  end

  it "should default to nil" do
    status = Status.new
    status.target.nil?.should be_truthy
    status.target.inspect.should == "nil"
  end

  it "should have boolean presence method" do
    status = Status.new
    status.target?.should be_falsey

    status.target = Project.new(:name => 'mongomapper')
    status.target?.should be_truthy
  end

  it "should be able to replace the association" do
    status = Status.new(:name => 'Foo!')
    project = Project.new(:name => "mongomapper")
    status.target = project
    status.save.should be_truthy

    status = status.reload
    status.target.nil?.should be_falsey
    status.target_id.should == project._id
    status.target_type.should == "Project"
    status.target.name.should == "mongomapper"
  end

  it "should unset the association" do
    status = Status.new(:name => 'Foo!')
    project = Project.new(:name => "mongomapper")
    status.target = project
    status.save.should be_truthy

    status = status.reload
    status.target = nil
    status.target_type.nil?.should be_truthy
    status.target_id.nil?.should be_truthy
    status.target.nil?.should be_truthy
  end

  context "association id set but document not found" do
    before do
      @status = Status.new(:name => 'Foo!')
      project = Project.new(:name => "mongomapper")
      @status.target = project
      @status.save.should be_truthy
      project.destroy
      @status.reload
    end

    it "should return nil instead of raising error" do
      @status.target.nil?.should be_truthy
    end
  end
end
