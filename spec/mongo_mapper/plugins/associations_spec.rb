require 'spec_helper'

describe MongoMapper::Plugins::Associations do
  describe '.associations' do
    it "should default associations to inherited class" do
      Message.associations.keys.should include(:room)
      Enter.associations.keys.should   include(:room)
      Exit.associations.keys.should    include(:room)
      Chat.associations.keys.should    include(:room)
    end
  end
end
