require 'spec_helper'

describe MongoMapper::Plugins::Associations::OneAssociation do
  Associations = MongoMapper::Plugins::Associations

  describe "type_key_name" do
    it "should be _type" do
      Associations::OneAssociation.new(:foo).type_key_name.should == '_type'
    end
  end

  context "embeddable?" do
    it "should be true if class is embeddable" do
      base = Associations::OneAssociation.new(:media)
      base.embeddable?.should be_true
    end

    it "should be false if class is not embeddable" do
      base = Associations::OneAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    it "should be OneProxy for one" do
      base = Associations::OneAssociation.new(:status)
      base.proxy_class.should == Associations::OneProxy
    end

    it "should be OneAsProxy for one with :as option" do
      base = Associations::OneAssociation.new(:message, :as => :messagable)
      base.proxy_class.should == Associations::OneAsProxy
    end

    it "should be OneEmbeddedProxy for one embedded" do
      base = Associations::OneAssociation.new(:media)
      base.proxy_class.should == Associations::OneEmbeddedProxy
    end

    it "should be OneEmbeddedPolymorphicProxy for polymorphic one embedded" do
      base = Associations::OneAssociation.new(:media, :polymorphic => true)
      base.proxy_class.should == Associations::OneEmbeddedPolymorphicProxy
    end
  end

end