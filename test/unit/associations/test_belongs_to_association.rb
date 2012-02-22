require 'test_helper'
require 'models'

class BelongsToAssociationTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

  context "class_name" do
    should "camelize the name" do
      BelongsToAssociation.new(:user).class_name.should == 'User'
    end

    should "be changeable using class_name option" do
      association = BelongsToAssociation.new(:user, :class_name => 'Person')
      association.class_name.should == 'Person'
    end
  end

  context "embeddable?" do
    should "be false even if class is embeddable" do
      base = BelongsToAssociation.new(:address)
      base.embeddable?.should be_false
    end

    should "be false if class is not embeddable" do
      base = BelongsToAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end
end