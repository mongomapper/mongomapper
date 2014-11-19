require 'spec_helper'

module BelongsToAssociation
  include MongoMapper::Plugins::Associations
  describe "BelongsToAssociation" do

    context "class_name" do
      it "should camelize the name" do
        BelongsToAssociation.new(:user).class_name.should == 'User'
      end

      it "should be changeable using class_name option" do
        association = BelongsToAssociation.new(:user, :class_name => 'Person')
        association.class_name.should == 'Person'
      end
    end

    context "embeddable?" do
      it "should be false even if class is embeddable" do
        base = BelongsToAssociation.new(:address)
        base.embeddable?.should be_falsey
      end

      it "should be false if class is not embeddable" do
        base = BelongsToAssociation.new(:project)
        base.embeddable?.should be_falsey
      end
    end
  end
end