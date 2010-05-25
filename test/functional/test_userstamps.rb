require 'test_helper'

class UserstampsTest < Test::Unit::TestCase
  context "userstamping" do
    setup do
      @document = Doc do
        userstamps!
      end
    end

    should "add creator_id key" do
      @document.keys.keys.should include('creator_id')
    end

    should "add updater_id key" do
      @document.keys.keys.should include('updater_id')
    end

    should "add belongs_to creator" do
      @document.associations.keys.should include('creator')
    end

    should "add belongs_to updater" do
      @document.associations.keys.should include('updater')
    end
  end
end