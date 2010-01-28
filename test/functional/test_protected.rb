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

    should "have protected attributes instance method" do
      @doc.protected_attributes.should equal(@doc_class.protected_attributes)
    end

    should 'assign protected attribute through accessor' do
      @doc.admin = true
      @doc.admin.should be_true
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