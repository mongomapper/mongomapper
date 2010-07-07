require 'test_helper'

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

class CallbacksTest < Test::Unit::TestCase
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
    setup do
      @document = Doc { include CallbacksSupport }
    end

    should "get the order right for creating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.history.should == CreateCallbackOrder
    end

    should "get the order right for updating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.clear_history
      doc.name = 'John'
      doc.save
      doc.history.should == UpdateCallbackOrder
    end
  
    should "work for before and after validation" do
      doc = @document.new(:name => 'John Nunemaker')
      doc.valid?
      doc.history.should include(:before_validation)
      doc.history.should include(:after_validation)
    end
  
    should "work for before and after create" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.history.should include(:before_create)
      doc.history.should include(:after_create)
    end
  
    should "work for before and after update" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.name = 'John Doe'
      doc.save
      doc.history.should include(:before_update)
      doc.history.should include(:after_update)
    end
  
    should "work for before and after save" do
      doc = @document.new
      doc.name = 'John Doe'
      doc.save
      doc.history.should include(:before_save)
      doc.history.should include(:after_save)
    end
  
    should "work for before and after destroy" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.destroy
      doc.history.should include(:before_destroy)
      doc.history.should include(:after_destroy)
    end
  end

  context "Defining and running callbacks on many embedded documents" do
    setup do
      @root_class        = Doc  { include CallbacksSupport }
      @child_class       = EDoc { include CallbacksSupport }
      @grand_child_class = EDoc { include CallbacksSupport }
  
      @root_class.many :children, :class => @child_class
      @child_class.many :children, :class => @grand_child_class
    end
  
    should "get the order right based on root document creation" do
      grand = @grand_child_class.new(:name => 'Grand Child')
      child = @child_class.new(:name => 'Child', :children => [grand])
      root  = @root_class.create(:name => 'Parent', :children => [child])
      
      child.history.should == CreateCallbackOrder
      grand.history.should == CreateCallbackOrder
    end
  
  #   should "get the order right based on root document updating" do
  #     grand = @grand_child_class.new(:name => 'Grand Child')
  #     child = @child_class.new(:name => 'Child', :children => [grand])
  #     root  = @root_class.create(:name => 'Parent', :children => [child])
  #     root.clear_history
  #     root.update_attributes(:name => 'Updated Parent')
  # 
  #     child = root.children.first
  #     child.history.should == UpdateCallbackOrder
  # 
  #     grand = root.children.first.children.first
  #     grand.history.should == UpdateCallbackOrder
  #   end
  # 
  #   should "work for before and after destroy" do
  #     grand = @grand_child_class.new(:name => 'Grand Child')
  #     child = @child_class.new(:name => 'Child', :children => [grand])
  #     root  = @root_class.create(:name => 'Parent', :children => [child])
  #     root.destroy
  #     child = root.children.first
  #     child.history.should include(:before_destroy)
  #     child.history.should include(:after_destroy)
  # 
  #     grand = root.children.first.children.first
  #     grand.history.should include(:before_destroy)
  #     grand.history.should include(:after_destroy)
  #   end
  # 
  #   should "not attempt to run callback defined on root that is not defined on embedded association" do
  #     @root_class.define_callbacks :after_publish
  #     @root_class.after_save { |d| d.run_callbacks(:after_publish) }
  # 
  #     assert_nothing_raised do
  #       child = @child_class.new(:name => 'Child')
  #       root  = @root_class.create(:name => 'Parent', :children => [child])
  #       child.history.should_not include(:after_publish)
  #     end
  #   end
  end
end