require 'test_helper'
require 'models'

class BelongsToAssociationTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

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