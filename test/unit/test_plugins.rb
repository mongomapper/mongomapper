require 'test_helper'

module MyPlugin
  module ClassMethods
    def class_foo
      'class_foo'
    end
  end
  
  module InstanceMethods
    def instance_foo
      'instance_foo'
    end
  end
end

class PluginsTest < Test::Unit::TestCase
  context "plugin" do
    setup do
      @document = Class.new do
        extend MongoMapper::Plugins
        plugin MyPlugin
      end
    end

    should "include instance methods" do
      @document.new.instance_foo.should == 'instance_foo'
    end
    
    should "extend class methods" do
      @document.class_foo.should == 'class_foo'
    end
    
    should "default plugins to empty array" do
      Class.new { extend MongoMapper::Plugins }.plugins.should == []
    end
    
    should "add plugin to plugins" do
      @document.plugins.should include(MyPlugin)
    end
  end
end