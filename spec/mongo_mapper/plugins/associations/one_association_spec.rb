require 'spec_helper'

describe MongoMapper::Plugins::Associations::OneAssociation do
  Associations = MongoMapper::Plugins::Associations

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
  end

end