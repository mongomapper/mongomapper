require 'spec_helper'

describe "Validations" do
  context "Saving a new document that is invalid" do
    before do
      @document = Doc do
        key :name, String, :required => true
      end
    end

    it "should not insert document" do
      doc = @document.new
      doc.save
      @document.count.should == 0
    end

    it "should populate document's errors" do
      doc = @document.new
      doc.errors.size.should == 0
      doc.save
      doc.errors.full_messages.should == ["Name can't be blank"]
    end
  end

  context "Saving a document that is invalid (destructive)" do
    before do
      @document = Doc do
        key :name, String, :required => true
      end
    end

    it "should raise error" do
      doc = @document.new
      lambda { doc.save! }.should raise_error(MongoMapper::DocumentNotValid)
    end

    it "should set document on exception" do
      doc = @document.new
      begin
        doc.save!
      rescue MongoMapper::DocumentNotValid => e
        e.document.should == doc
      end
    end
  end

  context "Creating a document that is invalid (destructive)" do
    before do
      @document = Doc do
        key :name, String, :required => true
      end
    end

    it "should raise error" do
      lambda { @document.create! }.should raise_error(MongoMapper::DocumentNotValid)
    end

    it "should create a new document" do
      instance = @document.create!(:name => "James")
      instance.new_record?.should be_falsey
    end
  end

  context "Saving an existing document that is invalid" do
    before do
      @document = Doc do
        key :name, String, :required => true
      end

      @doc = @document.create(:name => 'John Nunemaker')
    end

    it "should not update document" do
      @doc.name = nil
      @doc.save
      @doc.reload.name.should == 'John Nunemaker'
    end

    it "should populate document's errors" do
      @doc.name = nil
      @doc.save
      @doc.errors.full_messages.should == ["Name can't be blank"]
    end
  end

  context "Adding validation errors" do
    before do
      @document = Doc do
        key :action, String
        def action_present
          errors.add(:action, 'is invalid') if action.blank?
        end
      end
    end

    it "should work with validate :on => :create callback" do
      @document.validate :action_present, :on => :create

      doc = @document.create(:action => nil)
      doc.should have_error_on(:action)

      doc.action = 'kick'
      doc.save
      doc.should_not have_error_on(:action)
    end

    it "should work with validate :on => :update callback" do
      @document.validate :action_present, :on => :update

      doc = @document.new
      doc.action = nil
      doc.should_not have_error_on(:action)
      doc.save

      doc.action = nil
      doc.should have_error_on(:action)

      doc.action = 'kick'
      doc.should_not have_error_on(:action)
    end
  end

  context "validating uniqueness of" do
    before do
      @document = Doc do
        key :name, String
        validates_uniqueness_of :name
      end
    end

    it "should not fail if object is new" do
      doc = @document.new
      doc.should_not have_error_on(:name)
    end

    it "should not fail when new object is out of scope" do
      document = Doc do
        key :name
        key :adult
        validates_uniqueness_of :name, :scope => :adult
      end
      doc = document.new("name" => "joe", :adult => true)
      doc.save.should be_truthy

      doc2 = document.new("name" => "joe", :adult => false)
      doc2.should be_valid
    end

    it "should work with i18n taken message" do
      @document.create(:name => 'joe')
      doc = @document.create(:name => 'joe')
      doc.should have_error_on(:name, 'has already been taken')
    end

    it "should allow to update an object" do
      doc = @document.new("name" => "joe")
      doc.save.should be_truthy

      @document \
        .stub(:first) \
        .with(:name => 'joe') \
        .and_return(doc)

      doc.name = "joe"
      doc.valid?.should be_truthy
      doc.should_not have_error_on(:name)
    end

    it "should fail if object name is not unique" do
      doc = @document.new("name" => "joe")
      doc.save.should be_truthy

      @document \
        .stub(:first) \
        .with(:name => 'joe') \
        .and_return(doc)

      doc2 = @document.new("name" => "joe")
      doc2.should have_error_on(:name)
    end

    it "should allow multiple blank entries if :allow_blank => true" do
      document = Doc do
        key :name
        validates_uniqueness_of :name, :allow_blank => :true
      end

      doc = document.new("name" => "")
      doc.save.should be_truthy

      document \
        .stub(:first) \
        .with(:name => '') \
        .and_return(doc)

      doc2 = document.new("name" => "")
      doc2.should_not have_error_on(:name)
    end

    it "should allow multiple nil entries if :allow_nil => true" do
      document = Doc do
        key :name
        validates_uniqueness_of :name, :allow_nil => :true
      end

      doc = document.new('name' => nil)
      doc.save.should be_truthy

      doc2 = document.new('name' => nil)
      doc2.should_not have_error_on(:name)
    end

    it "should allow entries that differ only in case by default" do
      document = Doc do
        key :name
        validates_uniqueness_of :name
      end

      doc = document.new("name" => "BLAMMO")
      doc.save.should be_truthy

      doc2 = document.new("name" => "blammo")
      doc2.should_not have_error_on(:name)
    end

    context "with :case_sensitive => false" do
      before do
        @document = Doc do
          key :name
          validates_uniqueness_of :name, :case_sensitive => false
        end
      end

      it "should fail on entries that differ only in case" do
        doc = @document.new("name" => "BLAMMO")
        doc.save.should be_truthy

        doc2 = @document.new("name" => "blammo")
        doc2.should have_error_on(:name)
      end

      it "should not raise an error if value is nil" do
        doc = @document.new("name" => nil)
        lambda { doc.valid? }.should_not raise_error
      end

      it "should not raise an error if special Regexp characters used" do
        doc = @document.new("name" => '?')
        lambda { doc.valid? }.should_not raise_error
      end

      it "should check for uniqueness using entire string" do
        doc = @document.new("name" => "John Doe")
        doc.save.should be_truthy

        doc2 = @document.new("name" => "John")
        doc2.valid?.should be_truthy
      end
    end

    context "scoped by a single attribute" do
      before do
        @document = Doc do
          key :name, String
          key :scope, String
          validates_uniqueness_of :name, :scope => :scope
        end
      end

      it "should fail if the same name exists in the scope" do
        doc = @document.new("name" => "joe", "scope" => "one")
        doc.save.should be_truthy

        @document \
          .stub(:first) \
          .with(:name => 'joe', :scope => "one") \
          .and_return(doc)

        doc2 = @document.new("name" => "joe", "scope" => "one")
        doc2.should have_error_on(:name)
      end

      it "should pass if the same name exists in a different scope" do
        doc = @document.new("name" => "joe", "scope" => "one")
        doc.save.should be_truthy

        @document \
          .stub(:first) \
          .with(:name => 'joe', :scope => 'two') \
          .and_return(nil)

        doc2 = @document.new("name" => "joe", "scope" => "two")
        doc2.should_not have_error_on(:name)
      end
    end

    context "scoped by a multiple attributes" do
      before do
        @document = Doc do
          key :name, String
          key :first_scope, String
          key :second_scope, String
          validates_uniqueness_of :name, :scope => [:first_scope, :second_scope]
        end
      end

      it "should fail if the same name exists in the scope" do
        doc = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc.save.should be_truthy

        @document \
          .stub(:first) \
          .with(:name => 'joe', :first_scope => 'one', :second_scope => 'two') \
          .and_return(doc)

        doc2 = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc2.should have_error_on(:name)
      end

      it "should pass if the same name exists in a different scope" do
        doc = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "two")
        doc.save.should be_truthy

        @document \
          .stub(:first) \
          .with(:name => 'joe', :first_scope => 'one', :second_scope => 'one') \
          .and_return(nil)

        doc2 = @document.new("name" => "joe", "first_scope" => "one", "second_scope" => "one")
        doc2.should_not have_error_on(:name)
      end
    end
  end

  context "validating associated docs" do
    before do
      @child_class = EDoc do
        key :name, :required => true
      end

      @root_class = Doc { }
      @root_class.many :children, :class => @child_class
      @root_class.validates_associated :children, :message => 'are invalid'
    end

    it "should pass if there are no associated docs" do
      doc = @root_class.new
      doc.save.should be_truthy
    end

    it "should pass if the associated doc is valid" do
      doc = @root_class.new
      doc.children.build(:name => 'Joe')
      doc.save.should be_truthy
    end

    it "should fail if the associated doc is invalid" do
      doc = @root_class.new
      doc.children.build
      doc.should have_error_on(:children, 'are invalid')
    end

  end

  context "validating associated docs with custom context" do
    before do
      @child_class = EDoc do
        key :name

        validates_length_of :name, :minimum => 5, :on => :custom_context
      end

      @root_class = Doc { }
      @root_class.many :children, :class => @child_class
      @root_class.validates_associated :children, :context => :custom_context
    end

    it "should pass if there are no associated docs" do
      doc = @root_class.new
      doc.valid?(:custom_context).should be_truthy
    end

    it "should pass if the associated doc is valid" do
      doc = @root_class.new
      doc.children.build(:name => 'George')
      doc.valid?(:custom_context).should be_truthy
    end

    it "should fail if the associated doc is invalid" do
      doc = @root_class.new
      doc.children.build(:name => 'Bob')
      doc.valid?(:custom_context).should_not be_truthy
    end

  end
  # context "validates uniqueness of with :unique shortcut" do
  #   it "should work" do
  #     @document = Doc do
  #       key :name, String, :unique => true
  #     end
  #
  #     doc = @document.create(:name => 'John')
  #     doc.should_not have_error_on(:name)
  #
  #     @document \
  #       .stub(:first) \
  #       .with(:name => 'John') \
  #       .and_return(doc)
  #
  #     second_john = @document.create(:name => 'John')
  #     second_john.should have_error_on(:name, 'has already been taken')
  #   end
  # end
end
