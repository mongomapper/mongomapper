require 'spec_helper'

module CallbacksSupport
  def self.included base
    base.key :name, String

    [ :before_validation, :after_validation,
      :before_create,     :after_create,
      :before_update,     :after_update,
      :before_save,       :after_save,
      :before_destroy,    :after_destroy
    ].each do |callback|
      base.send(callback) do
        history << callback.to_sym
      end
    end
  end

  def history
    @history ||= []
  end

  def clear_history
    embedded_associations.each { |a| self.send(a.name).each(&:clear_history) }
    @history = nil
  end
end

describe "Callbacks" do
  CreateCallbackOrder = [
    :before_validation,
    :after_validation,
    :before_save,
    :before_create,
    :after_create,
    :after_save
  ]

  UpdateCallbackOrder = [
    :before_validation,
    :after_validation,
    :before_save,
    :before_update,
    :after_update,
    :after_save
  ]

  context "Defining and running callbacks on documents" do
    before do
      @document = Doc { include CallbacksSupport }
    end

    it "should get the order right for creating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.history.should == CreateCallbackOrder
    end

    it "should get the order right for updating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.clear_history
      doc.name = 'John'
      doc.save
      doc.history.should == UpdateCallbackOrder
    end

    it "should work for before and after validation" do
      doc = @document.new(:name => 'John Nunemaker')
      doc.valid?
      doc.history.should include(:before_validation)
      doc.history.should include(:after_validation)
    end

    it "should work for before and after create" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.history.should include(:before_create)
      doc.history.should include(:after_create)
    end

    it "should work for before and after update" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.name = 'John Doe'
      doc.save
      doc.history.should include(:before_update)
      doc.history.should include(:after_update)
    end

    it "should work for before and after save" do
      doc = @document.new
      doc.name = 'John Doe'
      doc.save
      doc.history.should include(:before_save)
      doc.history.should include(:after_save)
    end

    it "should work for before and after destroy" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.destroy
      doc.history.should include(:before_destroy)
      doc.history.should include(:after_destroy)
    end
  end

  context "Defining and running callbacks on many embedded documents" do
    before do
      @root_class        = Doc  { include CallbacksSupport }
      @child_class       = EDoc { include CallbacksSupport }
      @grand_child_class = EDoc { include CallbacksSupport }

      @root_class.many  :children, :class => @child_class
      @child_class.many :children, :class => @grand_child_class
    end

    it "should get the order right based on root document creation" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])

      root.children.first.history.should == CreateCallbackOrder
      root.children.first.children.first.history.should == CreateCallbackOrder
    end

    it "should get the order right based on root document updating" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])
      root.clear_history
      root.update_attributes(:name => 'Updated Parent')

      root.children.first.history.should == UpdateCallbackOrder
      root.children.first.children.first.history.should == UpdateCallbackOrder
    end

    it "should work for before and after destroy" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])
      root.destroy
      child = root.children.first
      child.history.should include(:before_destroy)
      child.history.should include(:after_destroy)

      grand = root.children.first.children.first
      grand.history.should include(:before_destroy)
      grand.history.should include(:after_destroy)
    end

    it "should not attempt to run callback defined on root that is not defined on embedded association" do
      @root_class.define_callbacks :after_publish
      @root_class.after_save { |d| d.run_callbacks(:after_publish) }

      expect {
        child = @child_class.new(:name => 'Child')
        root  = @root_class.create(:name => 'Parent', :children => [child])
        child.history.should_not include(:after_publish)
      }.to_not raise_error
    end
  end

  context "By default" do
    it "should not run callbacks when no callbacks were explicitly defined" do
      EDoc { key :name, String }.embedded_callbacks_off?.should == true
    end

    it "should run callbacks when a callback was explicitly defined" do
      EDoc {
        key :name, String
        before_save :no_op
        def noop; end
      }.embedded_callbacks_on?.should == true
    end
  end

  context "Turning embedded callbacks off" do
    before do
      @root_class        = Doc  { include CallbacksSupport; embedded_callbacks_off }
      @child_class       = EDoc { include CallbacksSupport; embedded_callbacks_off }
      @grand_child_class = EDoc { include CallbacksSupport; embedded_callbacks_off }

      @root_class.many  :children, :class => @child_class
      @child_class.many :children, :class => @grand_child_class
    end

    it "should not run create callbacks" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])

      root.children.first.history.should == []
      root.children.first.children.first.history.should == []
    end

    it "should not run update callbacks" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])
      root.clear_history
      root.update_attributes(:name => 'Updated Parent')

      root.children.first.history.should == []
      root.children.first.children.first.history.should == []
    end

    it "should not run destroy callbacks" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])
      root.destroy
      child = root.children.first
      child.history.should == []

      grand = root.children.first.children.first
      grand.history.should == []
    end
  end

  context "Running validation callbacks with conditional execution" do
    let(:document) do
      Doc do
        include CallbacksSupport
        key :message, String

        before_validation :set_message, :on => :create

        def set_message
          self['message'] = 'Hi!'
        end
      end
    end

    it 'should run callback on create' do
      doc = document.create
      doc.history.should include(:before_validation)
      doc.message.should == 'Hi!'
    end

    it 'should skip callback on update' do
      doc = document.create
      doc.message = 'Ho!'
      doc.save
      doc.message.should == 'Ho!'
    end
  end

  describe "after_find" do
    before do
      @found_objects = []
      found_objects = @found_objects # use a local for closure

      @doc_class = Doc("User") do
        after_find :set_found_object

        define_method :set_found_object do
          found_objects << self
        end
      end
    end

    it "should run after finding an object with find!" do
      @doc = @doc_class.create!

      @doc_class.find!(@doc.id)
      @found_objects.should == [@doc]
    end

    it "should not have run if nothing was queried" do
      @found_objects.should == []
    end

    it "should run for multiple objects" do
      @doc1 = @doc_class.create!
      @doc2 = @doc_class.create!

      @doc_class.all
      @found_objects.should == [@doc1, @doc2]
    end

    it "should run after finding an object through the query proxy" do
      @doc = @doc_class.create!
      @doc_class.where(:_id => @doc.id).first
      @found_objects.should == [@doc]
    end

    it "should still return the object" do
      @doc = @doc_class.create!
      @doc_class.where(:_id => @doc.id).first.should == @doc
    end

    it "should not bail if the method return false" do
      @doc_class = Doc("User") do
        after_find :set_found_object

        define_method :set_found_object do
          false
        end
      end

      @doc = @doc_class.create!
      @doc_class.where(:_id => @doc.id).first.should == @doc
    end
  end

  describe "after_initialize" do
    before do
      @objects = []
      objects = @objects

      @doc_class = Doc("User") do
        after_initialize :set_initialized_object

        define_method :set_initialized_object do
          objects << self
        end
      end
    end

    it "should be triggered for objects created with new" do
      @objects.should == []
      obj = @doc_class.new
      @objects.should == [obj]
    end

    it "should be triggered for objects found in the db" do
      @doc = @doc_class.create!
      @objects.clear # don't re-assign as we want the operation to be in place

      @doc_class.all
      @objects.should == [@doc]
    end
  end
end
