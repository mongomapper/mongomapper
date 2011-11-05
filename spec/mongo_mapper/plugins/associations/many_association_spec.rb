require 'spec_helper'

describe MongoMapper::Plugins::Associations::ManyAssociation do
  Associations = MongoMapper::Plugins::Associations

  context "class_name" do
    it "should camelize the name" do
      Associations::ManyAssociation.new(:smart_people).class_name.should == 'SmartPerson'
    end

    it "should be changeable using class_name option" do
      base = Associations::ManyAssociation.new(:smart_people, :class_name => 'IntelligentPerson')
      base.class_name.should == 'IntelligentPerson'
    end
  end

  context "type_key_name" do
    it "should be _type" do
      Associations::ManyAssociation.new(:foos).type_key_name.should == '_type'
    end
  end

  context "embeddable?" do
    it "should be true if class is embeddable" do
      base = Associations::ManyAssociation.new(:medias)
      base.embeddable?.should be_true
    end

    it "should be false if class is not embeddable" do
      base = Associations::ManyAssociation.new(:statuses)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    it "should be ManyDocumentsProxy for many" do
      base = Associations::ManyAssociation.new(:statuses)
      base.proxy_class.should == Associations::ManyDocumentsProxy
    end

    it "should be ManyPolymorphicProxy for polymorphic many" do
      base = Associations::ManyAssociation.new(:messages, :polymorphic => true)
      base.proxy_class.should == Associations::ManyPolymorphicProxy
    end

    it "should be ManyEmbeddedProxy for many embedded" do
      base = Associations::ManyAssociation.new(:medias)
      base.proxy_class.should == Associations::ManyEmbeddedProxy
    end

    it "should be ManyEmbeddedPolymorphicProxy for polymorphic many embedded" do
      base = Associations::ManyAssociation.new(:medias, :polymorphic => true)
      base.proxy_class.should == Associations::ManyEmbeddedPolymorphicProxy
    end

    it "should be InArrayProxy for many with :in option" do
      base = Associations::ManyAssociation.new(:messages, :in => :message_ids)
      base.proxy_class.should == Associations::InArrayProxy
    end
  end
end