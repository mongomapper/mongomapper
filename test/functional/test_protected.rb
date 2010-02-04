require 'test_helper'

class ProtectedTest < Test::Unit::TestCase
  context 'A document with protected attributes' do
    setup do
      @doc_class = Doc do
        key :name, String
        key :admin, Boolean, :default => false

        attr_protected :admin
      end

      @doc = @doc_class.create(:name => 'Steve Sloan')
    end

    should 'have protected attributes class method' do
      @doc_class.protected_attributes.should == [:admin].to_set
    end
    
    should "default protected attributes to nil" do
      Doc().protected_attributes.should be_nil
    end

    should "have protected attributes instance method" do
      @doc.protected_attributes.should equal(@doc_class.protected_attributes)
    end

    should "work with :protected shortcut when defining key" do
      Doc() do
        key :user_id, ObjectId, :protected => true
      end.protected_attributes.should == [:user_id].to_set
    end

    should 'assign protected attribute through accessor' do
      @doc.admin = true
      @doc.admin.should be_true
    end

    should "ignore protected attribute on #initialize" do
      doc = @doc_class.new(:name => 'John', :admin => true)
      doc.admin.should be_false
      doc.name.should == 'John'
    end

    should "not ignore protected attributes on #initialize from the database" do
      doc = @doc_class.new(:name => 'John')
      doc.admin = true
      doc.save!
      
      doc = @doc_class.first(:name => 'John')
      doc.admin.should be_true
      doc.name.should == 'John'
    end

    should 'ignore protected attribute on #update_attributes' do
      @doc.update_attributes(:name => 'Ren Hoek', :admin => true)
      @doc.name.should == 'Ren Hoek'
      @doc.admin.should be_false
    end

    should 'ignore protected attribute on #update_attributes!' do
      @doc.update_attributes!(:name => 'Stimpson J. Cat', :admin => true)
      @doc.name.should == 'Stimpson J. Cat'
      @doc.admin.should be_false
    end
  end
  
  context "Single collection inherited protected attributes" do
    setup do
      class ::GrandParent
        include MongoMapper::Document

        key :_type, String
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

    teardown do
      Object.send :remove_const, 'GrandParent' if defined?(::GrandParent)
      Object.send :remove_const, 'Child'       if defined?(::Child)
      Object.send :remove_const, 'GrandChild'  if defined?(::GrandChild)
      Object.send :remove_const, 'OtherChild'  if defined?(::OtherChild)
    end

    should "share keys down the inheritance trail" do
      GrandParent.protected_attributes.should == [:site_id].to_set
      Child.protected_attributes.should == [:site_id, :position].to_set
      GrandChild.protected_attributes.should == [:site_id, :position].to_set
      OtherChild.protected_attributes.should == [:site_id, :blog_id].to_set
    end
  end

  context 'An embedded document with protected attributes' do
    setup do
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

    should 'have protected attributes class method' do
      @edoc_class.protected_attributes.should == [:admin].to_set
    end
    
    should "default protected attributes to nil" do
      EDoc().protected_attributes.should be_nil
    end

    should "have protected attributes instance method" do
      @edoc.protected_attributes.should equal(@edoc_class.protected_attributes)
    end

    should 'assign protected attribute through accessor' do
      @edoc.admin = true
      @edoc.admin.should be_true
    end

    should 'ignore protected attribute on #update_attributes' do
      @edoc.update_attributes(:name => 'Ren Hoek', :admin => true)
      @edoc.name.should == 'Ren Hoek'
      @edoc.admin.should be_false
    end

    should 'ignore protected attribute on #update_attributes!' do
      @edoc.update_attributes!(:name => 'Stimpson J. Cat', :admin => true)
      @edoc.name.should == 'Stimpson J. Cat'
      @edoc.admin.should be_false
    end
  end
end