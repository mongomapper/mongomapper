require 'test_helper'

class CallbacksTest < Test::Unit::TestCase
  context "Defining and running callbacks" do
    setup do
      @document = Class.new do
        include MongoMapper::Document
        
        key :name, String
        
        [ :before_validation_on_create, :before_validation_on_update,
          :before_validation, :after_validation,
          :before_create,     :after_create, 
          :before_update,     :after_update,
          :before_save,       :after_save,
          :before_destroy,    :after_destroy].each do |callback|
          callback_method = "#{callback}_callback"
          send(callback, callback_method)
          define_method(callback_method) do
            history << callback.to_sym
          end
        end
        
        def history
          @history ||= []
        end
        
        def clear_history
          @history = nil
        end
      end
      
      clear_all_collections
    end
    
    should "get the order right for creating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.history.should == [:before_validation, :before_validation_on_create, :after_validation, :before_save, :before_create, :after_create, :after_save]
    end
    
    should "get the order right for updating documents" do
      doc = @document.create(:name => 'John Nunemaker')
      doc.clear_history
      doc.name = 'John'
      doc.save
      doc.history.should == [:before_validation, :before_validation_on_update, :after_validation, :before_save, :before_update, :after_update, :after_save]
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
end