require 'test_helper'
require 'models'

class OneAssociationTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

  context "type_key_name" do
    should "be _type" do
      OneAssociation.new(:foo).type_key_name.should == '_type'
    end
  end

  context "embeddable?" do
    should "be true if class is embeddable" do
      base = OneAssociation.new(:media)
      base.embeddable?.should be_true
    end

    should "be false if class is not embeddable" do
      base = OneAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    should "be OneProxy for one" do
      base = OneAssociation.new(:status)
      base.proxy_class.should == OneProxy
    end

    should "be OneAsProxy for one with :as option" do
      base = OneAssociation.new(:message, :as => :messagable)
      base.proxy_class.should == OneAsProxy
    end

    should "be OneEmbeddedProxy for one embedded" do
      base = OneAssociation.new(:media)
      base.proxy_class.should == OneEmbeddedProxy
    end

    should "be OneEmbeddedPolymorphicProxy for polymorphic one embedded" do
      base = OneAssociation.new(:media, :polymorphic => true)
      base.proxy_class.should == OneEmbeddedPolymorphicProxy
    end
  end

end