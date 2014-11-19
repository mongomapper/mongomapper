require 'spec_helper'


module ManyAssociationSpec
  include MongoMapper::Plugins::Associations
  describe "ManyAssociation" do

    context "class_name" do
      it "should camelize the name" do
        ManyAssociation.new(:smart_people).class_name.should == 'SmartPerson'
      end

      it "should be changeable using class_name option" do
        base = ManyAssociation.new(:smart_people, :class_name => 'IntelligentPerson')
        base.class_name.should == 'IntelligentPerson'
      end
    end

    context "type_key_name" do
      it "should be _type" do
        ManyAssociation.new(:foos).type_key_name.should == '_type'
      end
    end

    context "embeddable?" do
      it "should be true if class is embeddable" do
        base = ManyAssociation.new(:medias)
        base.embeddable?.should be_truthy
      end

      it "should be false if class is not embeddable" do
        base = ManyAssociation.new(:statuses)
        base.embeddable?.should be_falsey
      end
    end

    context "proxy_class" do
      it "should be ManyDocumentsProxy for many" do
        base = ManyAssociation.new(:statuses)
        base.proxy_class.should == ManyDocumentsProxy
      end

      it "should be ManyPolymorphicProxy for polymorphic many" do
        base = ManyAssociation.new(:messages, :polymorphic => true)
        base.proxy_class.should == ManyPolymorphicProxy
      end

      it "should be ManyEmbeddedProxy for many embedded" do
        base = ManyAssociation.new(:medias)
        base.proxy_class.should == ManyEmbeddedProxy
      end

      it "should be ManyEmbeddedPolymorphicProxy for polymorphic many embedded" do
        base = ManyAssociation.new(:medias, :polymorphic => true)
        base.proxy_class.should == ManyEmbeddedPolymorphicProxy
      end

      it "should be InArrayProxy for many with :in option" do
        base = ManyAssociation.new(:messages, :in => :message_ids)
        base.proxy_class.should == InArrayProxy
      end
    end
  end
end