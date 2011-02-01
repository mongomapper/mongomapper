require 'test_helper'
require 'models'

class OneAssociationTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

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
end