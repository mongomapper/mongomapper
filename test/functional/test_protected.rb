require 'test_helper'

class ProtectedTest < Test::Unit::TestCase
  context 'A document with protected attributes' do
    setup do
      @doc_class = Doc do
        set_collection_name 'users'
        key :name, String
        key :admin, Boolean

        attr_protected :admin
      end

      @doc = @doc_class.create( :name => 'Steve Sloan', :admin => false )
      @doc.admin.should == false
    end

    should 'have protected attributes' do
      @doc_class.protected_attributes.to_a.should == [:admin]
      @doc.class.protected_attributes.to_a.should == [:admin]
    end

    should 'assign protected attribute through accessor' do
      @doc.admin = true
      @doc.save!
      @doc.admin.should == true
    end

    should 'ignore protected attribute on #update_attributes' do
      @doc.update_attributes( :name => 'Ren Hoek', :admin => true )
      @doc.name.should == 'Ren Hoek'
      @doc.admin.should == false
    end

    should 'ignore protected attribute on #update_attributes!' do
      @doc.update_attributes!( :name => 'Stimpson J. Cat', :admin => true )
      @doc.name.should == 'Stimpson J. Cat'
      @doc.admin.should == false
    end
  end
end