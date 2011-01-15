require 'test_helper'
require 'models'

class ManyAssociationTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

  context "class_name" do
    should "camelize the name" do
      ManyAssociation.new(:smart_people).class_name.should == 'SmartPerson'
    end

    should "be changeable using class_name option" do
      base = ManyAssociation.new(:smart_people, :class_name => 'IntelligentPerson')
      base.class_name.should == 'IntelligentPerson'
    end
  end

  context "type_key_name" do
    should "be _type" do
      ManyAssociation.new(:foos).type_key_name.should == '_type'
    end
  end

  context "embeddable?" do
    should "be true if class is embeddable" do
      base = ManyAssociation.new(:medias)
      base.embeddable?.should be_true
    end

    should "be false if class is not embeddable" do
      base = ManyAssociation.new(:statuses)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    should "be ManyDocumentsProxy for many" do
      base = ManyAssociation.new(:statuses)
      base.proxy_class.should == ManyDocumentsProxy
    end

    should "be ManyPolymorphicProxy for polymorphic many" do
      base = ManyAssociation.new(:messages, :polymorphic => true)
      base.proxy_class.should == ManyPolymorphicProxy
    end

    should "be ManyEmbeddedProxy for many embedded" do
      base = ManyAssociation.new(:medias)
      base.proxy_class.should == ManyEmbeddedProxy
    end

    should "be ManyEmbeddedPolymorphicProxy for polymorphic many embedded" do
      base = ManyAssociation.new(:medias, :polymorphic => true)
      base.proxy_class.should == ManyEmbeddedPolymorphicProxy
    end

    should "be InArrayProxy for many with :in option" do
      base = ManyAssociation.new(:messages, :in => :message_ids)
      base.proxy_class.should == InArrayProxy
    end
  end

end