require 'spec_helper'

describe MongoMapper::Plugins::Associations::BelongsToAssociation do
  Associations = MongoMapper::Plugins::Associations

  context "class_name" do
    it "should camelize the name" do
      Associations::BelongsToAssociation.new(:user).class_name.should == 'User'
    end

    it "should be changeable using class_name option" do
      association = Associations::BelongsToAssociation.new(:user, :class_name => 'Person')
      association.class_name.should == 'Person'
    end
  end

  context "embeddable?" do
    it "should be false even if class is embeddable" do
      base = Associations::BelongsToAssociation.new(:address)
      base.embeddable?.should be_false
    end

    it "should be false if class is not embeddable" do
      base = Associations::BelongsToAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end
end