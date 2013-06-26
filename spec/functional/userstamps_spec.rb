require 'spec_helper'

module Userstamps
  describe "Userstamps" do
    class AltUser
      include MongoMapper::Document
    end

    context "userstamping" do
      before do
        @document = Doc do
          userstamps!
        end
        @document_alt_user = Doc do
          userstamps! :class_name => 'Userstamps::AltUser'
        end
        @document_alt_user_class = Doc do
          userstamps! :class => Userstamps::AltUser
        end
        @docs = [@document, @document_alt_user, @document_alt_user_class]
      end

      it "should add creator_id key" do
        @docs.each{ |d| d.keys.should include('creator_id') }
      end

      it "should add updater_id key" do
        @docs.each{ |d| d.keys.should include('updater_id') }
      end

      it "should add belongs_to creator" do
        @docs.each{ |d| d.associations.keys.should include(:creator) }
      end

      it "should add belongs_to updater" do
        @docs.each{ |d| d.associations.keys.should include(:updater) }
      end

      it "should properly set class names" do
        @document.associations[:creator].class_name.should == 'User'
        @document_alt_user.associations[:creator].class_name.should == 'Userstamps::AltUser'
        @document_alt_user_class.associations[:creator].class_name.should == 'Userstamps::AltUser'
      end
    end
  end
end