require 'test_helper'

class ValidationsTest < Test::Unit::TestCase
  context "Saving a new document that is invalid" do
    setup do
      @document = Doc do
        key :name, String, :required => true
      end
    end
  
    should "not insert document" do
      doc = @document.new
      doc.save
      @document.count.should == 0
    end
  
    should "populate document's errors" do
      doc = @document.new
      doc.errors.size.should == 0
      doc.save
      doc.errors.full_messages.should == ["Name can't be blank"]
    end
  end
  
  context "Saving a document that is invalid (destructive)" do
    setup do
      @document = Doc do
        key :name, String, :required => true
      end
    end
  
    should "raise error" do
      doc = @document.new
      lambda { doc.save! }.should raise_error(MongoMapper::DocumentNotValid)
    end
  end
  
  context "Creating a document that is invalid (destructive)" do
    setup do
      @document = Doc do
        key :name, String, :required => true
      end
    end
  
    should "raise error" do
      lambda { @document.create! }.should raise_error(MongoMapper::DocumentNotValid)
    end
  
    should "create a new document" do
      instance = @document.create!(:name => "James")
      instance.new_record?.should be_false
    end
  end

  context "Saving an existing document that is invalid" do
    setup do
      @document = Doc do
        key :name, String, :required => true
      end
  
      @doc = @document.create(:name => 'John Nunemaker')
    end
  
    should "not update document" do
      @doc.name = nil
      @doc.save
      @doc.reload.name.should == 'John Nunemaker'
    end
  
    should "populate document's errors" do
      @doc.name = nil
      @doc.save
      @doc.errors.full_messages.should == ["Name can't be blank"]
    end
  end

  context "Adding validation errors" do
    setup do
      @document = Doc do
        key :action, String
        def action_present
          errors.add(:action, 'is invalid') if action.blank?
        end
      end
    end
  
    should "work with validate_on_create callback" do
      @document.validate :action_present, :on => :create
  
      doc = @document.create(:action => nil)
      doc.should have_error_on(:action)
  
      doc.action = 'kick'
      doc.save
      doc.should_not have_error_on(:action)
    end
  
    # should "work with validate_on_update callback" do
    #   @document.validate :action_present, :on => :update
    #   
    #   doc = @document.new
    #   doc.action = nil
    #   doc.should_not have_error_on(:action)
    #   doc.save
    #   
    #   doc.action = nil
    #   doc.should have_error_on(:action)
    #   
    #   doc.action = 'kick'
    #   doc.should_not have_error_on(:action)
    # end
  end

  context "validating uniqueness of" do
    setup do
      @document = Doc do
        key :name, String
        validates_uniqueness_of :name
      end
    end

    should "not fail if object is new" do
      doc = @document.new
      doc.should_not have_error_on(:name)
    end

    should "not fail when new object is out of scope" do
      document = Doc do
        key :name
        key :adult
        validates_uniqueness_of :name, :scope => :adult
      end
      doc = document.new("name" => "joe", :adult => true)
      doc.save.should be_true
    
      doc2 = document.new("name" => "joe", :adult => false)
      doc2.should be_valid
    end

    should "allow to update an object" do
      doc = @document.new("name" => "joe")
      doc.save.should be_true
    
      @document \
        .stubs(:first) \
        .with(:name => 'joe') \
        .returns(doc)
    
      doc.name = "joe"
      doc.valid?.should be_true
      doc.should_not have_error_on(:name)
    end
    
    should "fail if object name is not unique" do
      doc = @document.new("name" => "joe")
      doc.save.should be_true
    
      @document \
        .stubs(:first) \
        .with(:name => 'joe') \
        .returns(doc)
    
      doc2 = @document.new("name" => "joe")
      doc2.should have_error_on(:name)
    end
    
    should "allow multiple blank entries if :allow_blank => true" do
      document = Doc do
        key :name
        validates_uniqueness_of :name, :allow_blank => :true
      end
    
      doc = document.new("name" => "")
      doc.save.should be_true
    
      document \
        .stubs(:first) \
        .with(:name => '') \
        .returns(doc)
    
      doc2 = document.new("name" => "")
      doc2.should_not have_error_on(:name)
    end
    
    should "allow multiple nil entries if :allow_nil => true" do
      document = Doc do
        key :name
        validates_uniqueness_of :name, :allow_nil => :true
      end
    
      doc = document.new('name' => nil)
      doc.save.should be_true
    
      doc2 = document.new('name' => nil)
      doc2.should_not have_error_on(:name)
    end
    
    should "allow entries that differ only in case by default" do
      document = Doc do
        key :name
        validates_uniqueness_of :name
      end
    
      doc = document.new("name" => "BLAMMO")
      doc.save.should be_true
    
      doc2 = document.new("name" => "blammo")
      doc2.should_not have_error_on(:name)
    end

    context "with :case_sensitive => false" do
      setup do
        @document = Doc do
          key :name
          validates_uniqueness_of :name, :case_sensitive => false
        end
      end
    
      should "fail on entries that differ only in case" do
        doc = @document.new("name" => "BLAMMO")
        doc.save.should be_true
    
        doc2 = @document.new("name" => "blammo")
        doc2.should have_error_on(:name)
      end
    
      should "not raise an error if value is nil" do
        doc = @document.new("name" => nil)
        lambda { doc.valid? }.should_not raise_error
      end
    
      should "not raise an error if special Regexp characters used" do
        doc = @document.new("name" => '?')
        lambda { doc.valid? }.should_not raise_error
      end
    
      should "check for uniqueness using entire string" do
        doc = @document.new("name" => "John Doe")
        doc.save.should be_true
    
        doc2 = @document.new("name" => "John")
        doc2.valid?.should be_true
      end
    end

    context "scoped by a single attribute" do
      setup do
        @document = Doc do
          key :name, String
          key :scope, String
          validates_uniqueness_of :name, :scope => :scope
        end
      end
    
      should "fail if the same name exists in the scope" do
        doc = @document.new("name" => "joe", "scope" => "one")
        doc.save.should be_true
    
        @document \
          .stubs(:first) \
          .with(:name => 'joe', :scope => "one") \
          .returns(doc)
    
        doc2 = @document.new("name" => "joe", "scope" => "one")
        doc2.should have_error_on(:name)
      end
    
      should "pass if the same name exists in a different scope" do
        doc = @document.new("name" => "joe", "scope" => "one")
        doc.save.should be_true
    
        @document \
          .stubs(:first) \
          .with(:name => 'joe', :scope => 'two') \
          .returns(nil)
    
        doc2 = @document.new("name" => "joe", "scope" => "two")
        doc2.should_not have_error_on(:name)
      end
    end

    context "scoped by a multiple attributes" do
      setup do
        @document = Doc do
          key :name, String
          key :first_scope, String
          key :second_scope, String
          validates_uniqueness_of :name, :scope => [:first_scope, :second_scope]
        end
      end
  
      should "fail if the same name exists in the scope" do
        doc = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc.save.should be_true
  
        @document \
          .stubs(:first) \
          .with(:name => 'joe', :first_scope => 'one', :second_scope => 'two') \
          .returns(doc)
  
        doc2 = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc2.should have_error_on(:name)
      end
  
      should "pass if the same name exists in a different scope" do
        doc = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc.save.should be_true
  
        @document \
          .stubs(:first) \
          .with(:name => 'joe', :first_scope => 'one', :second_scope => 'one') \
          .returns(nil)
  
        doc2 = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "one")
        doc2.should_not have_error_on(:name)
      end
    end
  end

  # context "validates uniqueness of with :unique shortcut" do
  #   should "work" do
  #     @document = Doc do
  #       key :name, String, :unique => true
  #     end
  # 
  #     doc = @document.create(:name => 'John')
  #     doc.should_not have_error_on(:name)
  # 
  #     @document \
  #       .stubs(:first) \
  #       .with(:name => 'John') \
  #       .returns(doc)
  # 
  #     second_john = @document.create(:name => 'John')
  #     second_john.should have_error_on(:name, 'has already been taken')
  #   end
  # end
end
