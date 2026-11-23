require 'spec_helper'

describe "Plugins" do
  it "should default plugins to empty array" do
    Class.new { extend MongoMapper::Plugins }.plugins.should == []
  end

  context "direct_descendants" do
    def build_and_forget(count)
      count.times.map { yield.object_id }
    end

    def live_descendant_ids(mod, ids)
      mod.direct_descendants.map(&:object_id) & ids
    end

    [
      ["Document",         MongoMapper::Document,         lambda { Doc() }],
      ["EmbeddedDocument", MongoMapper::EmbeddedDocument, lambda { EDoc() }],
    ].each do |label, mod, builder|
      it "should not retain #{label} models that are no longer referenced" do
        skip "GC is not deterministic on JRuby" if RUBY_ENGINE == "jruby"

        ids = build_and_forget(20) { builder.call }

        3.times { GC.start(full_mark: true, immediate_sweep: true) }

        live_descendant_ids(mod, ids).size.should < 20
      end
    end

    it "should track models that are still referenced" do
      model = Doc()
      MongoMapper::Document.direct_descendants.should include(model)
    end
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

    before do
      @document = Class.new do
        extend MongoMapper::Plugins
        plugin MyConcern
      end
    end

    it "should include instance methods" do
      @document.new.instance_foo.should == 'instance_foo'
    end

    it "should extend class methods" do
      @document.class_foo.should == 'class_foo'
    end

    it "should pass model to configure" do
      @document.new.should respond_to(:from_concern)
    end

    it "should add plugin to plugins" do
      @document.plugins.should include(MyConcern)
    end

    context "Document" do
      before do
        MongoMapper::Document.plugins.delete(MyConcern)
      end

      it 'should allow plugins on Document' do
        MongoMapper::Document.plugin(MyConcern)
        Doc().should respond_to(:class_foo)
        Doc().new.should respond_to(:instance_foo)
      end

      it 'should add plugins to classes that include Document before they are added' do
        article = Doc()
        MongoMapper::Document.plugin(MyConcern)
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end
    end

    context "EmbeddedDocument" do
      before do
        MongoMapper::EmbeddedDocument.plugins.delete(MyConcern)
      end

      it 'should allow plugins on EmbeddedDocument' do
        MongoMapper::EmbeddedDocument.plugin(MyConcern)
        article = EDoc()
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end

      it 'should add plugins to classes that include EmbeddedDocument before they are added' do
        article = EDoc()
        MongoMapper::EmbeddedDocument.plugin(MyConcern)
        article.should respond_to(:class_foo)
        article.new.should respond_to(:instance_foo)
      end
    end
  end
end