require 'spec_helper'


module OneAssociationSpec
  include MongoMapper::Plugins::Associations
  describe "OneAssociation" do

    context "type_key_name" do
      it "should be _type" do
        OneAssociation.new(:foo).type_key_name.should == '_type'
      end
    end

    context "embeddable?" do
      it "should be true if class is embeddable" do
        base = OneAssociation.new(:media)
        base.embeddable?.should be_truthy
      end

      it "should be false if class is not embeddable" do
        base = OneAssociation.new(:project)
        base.embeddable?.should be_falsey
      end
    end

    context "proxy_class" do
      it "should be OneProxy for one" do
        base = OneAssociation.new(:status)
        base.proxy_class.should == OneProxy
      end

      it "should be OneAsProxy for one with :as option" do
        base = OneAssociation.new(:message, :as => :messagable)
        base.proxy_class.should == OneAsProxy
      end

      it "should be OneEmbeddedProxy for one embedded" do
        base = OneAssociation.new(:media)
        base.proxy_class.should == OneEmbeddedProxy
      end

      it "should be OneEmbeddedPolymorphicProxy for polymorphic one embedded" do
        base = OneAssociation.new(:media, :polymorphic => true)
        base.proxy_class.should == OneEmbeddedPolymorphicProxy
      end
    end
  end
end