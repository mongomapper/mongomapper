require 'test_helper'

class UserstampsTest < Test::Unit::TestCase
  context "userstamping" do
    setup do
      @document = Doc do
        userstamps!
      end
      @document_alt_user = Doc do
        userstamps! 'AltUser'
      end
      @document_for_alt_user = Doc do
        userstamps_for! 'AltUser'
      end
    end

    should "add creator_id key" do
      [@document, @document_alt_user, @document_for_alt_user].each{ |d| d.keys.keys.should include('creator_id') }
    end

    should "add updater_id key" do
      [@document, @document_alt_user, @document_for_alt_user].each{ |d| d.keys.keys.should include('updater_id') }
    end

    should "add belongs_to creator" do
      [@document, @document_alt_user, @document_for_alt_user].each{ |d| d.associations.keys.should include(:creator) }
    end

    should "add belongs_to updater" do
      [@document, @document_alt_user, @document_for_alt_user].each{ |d| d.associations.keys.should include(:updater) }
    end
  end
end