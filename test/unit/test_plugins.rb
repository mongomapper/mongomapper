require 'test_helper'

class PluginsTest < Test::Unit::TestCase
  should "default plugins to empty array" do
    Class.new { extend MongoMapper::Plugins }.plugins.should == []
  end

  context "a plugin" do
    module MyConcern
      extend ActiveSupport::Concern

      included do
        attr_accessor :from_concern
      end

      module ClassMethods
        def class_foo
          'class_foo'
        end
      end

      def instance_foo
        'instance_foo'
      end
    end

    setup do
      @document = Class.new do
        extend MongoMapper::Plugins
        plugin MyConcern
      end
    end

    should "include instance methods" do
      @document.new.instance_foo.should == 'instance_foo'
    end

    should "extend class methods" do
      @document.class_foo.should == 'class_foo'
    end

    should "pass model to configure" do
      @document.new.should respond_to(:from_concern)
    end

    should "add plugin to plugins" do
      @document.plugins.should include(MyConcern)
    end

    context "Document" do
      setup do
        MongoMapper::Document.plugins.delete(MyConcern)
      end

      should 'allow plugins on Document' do
        MongoMapper::Document.plugin(MyConcern)
        Doc().should respond_to(:class_foo)
        Doc().new.should respond_to(:instance_foo)
      end

      should 'add plugins to classes that include Document before they are added' do
        article = Doc()
        MongoMapper::Document.plugin(MyConcern)
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end
    end

    context "EmbeddedDocument" do
      setup do
        MongoMapper::EmbeddedDocument.plugins.delete(MyConcern)
      end

      should 'allow plugins on EmbeddedDocument' do
        MongoMapper::EmbeddedDocument.plugin(MyConcern)
        article = EDoc()
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end

      should 'add plugins to classes that include EmbeddedDocument before they are added' do
        article = EDoc()
        MongoMapper::EmbeddedDocument.plugin(MyConcern)
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end
    end
  end
end