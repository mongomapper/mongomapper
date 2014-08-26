require 'spec_helper'

describe 'A document with protected attributes' do
  before do
    @doc_class = Doc do
      key :name, String
      key :admin, Boolean, :default => false

      attr_protected :admin
    end

    @doc = @doc_class.create(:name => 'Steve Sloan')
  end

  it "should have protected attributes class method" do
    @doc_class.protected_attributes.should == [:admin].to_set
  end

  it "should default protected attributes to nil" do
    Doc().protected_attributes.should be_nil
  end

  it "should have protected attributes instance method" do
    @doc.protected_attributes.should equal(@doc_class.protected_attributes)
  end

  it "should raise error if there are accessible attributes" do
    doc = Doc('Post')
    doc.attr_accessible :name
    lambda { doc.attr_protected :admin }.
      should raise_error(/Declare either attr_protected or attr_accessible for Post/)
  end

  it "should know if using protected attributes" do
    @doc_class.protected_attributes?.should be(true)
    Doc().protected_attributes?.should be(false)
  end

  it "should work with :protected shortcut when defining key" do
    Doc() do
      key :user_id, ObjectId, :protected => true
    end.protected_attributes.should == [:user_id].to_set
  end

  it "should assign protected attribute through accessor" do
    @doc.admin = true
    @doc.admin.should be_truthy
  end

  it "should ignore protected attribute on #initialize" do
    doc = @doc_class.new(:name => 'John', :admin => true)
    doc.admin.should be_falsey
    doc.name.should == 'John'
  end

  it "should not ignore protected attributes on #initialize from the database" do
    doc = @doc_class.new(:name => 'John')
    doc.admin = true
    doc.save!

    doc = @doc_class.first(:name => 'John')
    doc.admin.should be_truthy
    doc.name.should == 'John'
  end

  it "should not ignore protected attributes on #reload" do
    doc = @doc_class.new(:name => 'John')
    doc.admin = true
    doc.save!

    doc.reload
    doc.admin.should be_truthy
    doc.name.should == 'John'
  end

  it "should ignore protected attribute on #update_attribute" do
    @doc.update_attribute('admin', true)
    @doc.admin.should be_truthy
  end

  it "should ignore protected attribute on #update_attributes" do
    @doc.update_attributes(:name => 'Ren Hoek', :admin => true)
    @doc.name.should == 'Ren Hoek'
    @doc.admin.should be_falsey
  end

  it "should ignore protected attribute on #update_attributes!" do
    @doc.update_attributes!(:name => 'Stimpson J. Cat', :admin => true)
    @doc.name.should == 'Stimpson J. Cat'
    @doc.admin.should be_falsey
  end

  it "should ignore protecteds attribute on #attributes=" do
    @doc.attributes = {:name => 'Stimpson J. Cat', :admin => true}
    @doc.name.should == 'Stimpson J. Cat'
    @doc.admin.should be_falsey
  end

  it "should be indifferent to whether the protected keys are strings or symbols" do
    @doc.update_attributes!("name" => 'Stimpson J. Cat', "admin" => true)
    @doc.name.should == 'Stimpson J. Cat'
    @doc.admin.should be_falsey
  end

  it "should accept nil as constructor's argument without raising exception" do
    lambda { @doc_class.new(nil) }.should_not raise_error
  end
end

describe "Single collection inherited protected attributes" do
  before do
    class ::GrandParent
      include MongoMapper::Document

      key :site_id, ObjectId
      attr_protected :site_id
    end
    GrandParent.collection.remove

    class ::Child < ::GrandParent
      key :position, Integer

      attr_protected :position
    end

    class ::GrandChild < ::Child; end

    class ::OtherChild < ::GrandParent
      key :blog_id, ObjectId

      attr_protected :blog_id
    end
  end

  after do
    Object.send :remove_const, 'GrandParent' if defined?(::GrandParent)
    Object.send :remove_const, 'Child'       if defined?(::Child)
    Object.send :remove_const, 'GrandChild'  if defined?(::GrandChild)
    Object.send :remove_const, 'OtherChild'  if defined?(::OtherChild)
  end

  it "should share keys down the inheritance trail" do
    GrandParent.protected_attributes.should == [:site_id].to_set
    Child.protected_attributes.should == [:site_id, :position].to_set
    GrandChild.protected_attributes.should == [:site_id, :position].to_set
    OtherChild.protected_attributes.should == [:site_id, :blog_id].to_set
  end
end

describe 'An embedded document with protected attributes' do
  before do
    @doc_class = Doc('Project')
    @edoc_class = EDoc('Person') do
      key :name, String
      key :admin, Boolean, :default => false

      attr_protected :admin
    end
    @doc_class.many :people, :class => @edoc_class

    @doc = @doc_class.create(:title => 'MongoMapper')
    @edoc = @edoc_class.new(:name => 'Steve Sloan')
    @doc.people << @edoc
  end

  it "should have protected attributes class method" do
    @edoc_class.protected_attributes.should == [:admin].to_set
  end

  it "should default protected attributes to nil" do
    EDoc().protected_attributes.should be_nil
  end

  it "should have protected attributes instance method" do
    @edoc.protected_attributes.should equal(@edoc_class.protected_attributes)
  end

  it "should assign protected attribute through accessor" do
    @edoc.admin = true
    @edoc.admin.should be_truthy
  end

  it "should not ignore protected attribute on #update_attribute" do
    @edoc.update_attribute('admin', true)
    @edoc.admin.should be_truthy
  end

  it "should ignore protected attribute on #update_attributes" do
    @edoc.update_attributes(:name => 'Ren Hoek', :admin => true)
    @edoc.name.should == 'Ren Hoek'
    @edoc.admin.should be_falsey
  end

  it "should ignore protected attribute on #update_attributes!" do
    @edoc.update_attributes!(:name => 'Stimpson J. Cat', :admin => true)
    @edoc.name.should == 'Stimpson J. Cat'
    @edoc.admin.should be_falsey
  end
end