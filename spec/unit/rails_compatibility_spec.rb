require 'spec_helper'

describe "Rails Compatibility" do
  module EmbeddedDocuments
    class Item
      include MongoMapper::EmbeddedDocument
      key :for_all, String
    end

    class FirstItem < Item
      key :first_only, String
      many :second_items
    end

    class SecondItem < Item
      key :second_only, String
    end
  end

  context "EmbeddedDocument" do
    it "should alias many to has_many" do
      EmbeddedDocuments::FirstItem.should respond_to(:has_many)
    end

    it "should alias one to has_one" do
      EmbeddedDocuments::FirstItem.should respond_to(:has_one)
    end

    it "should have column names" do
      EmbeddedDocuments::Item.column_names.sort.should == ['_id', '_type', 'for_all']
      EmbeddedDocuments::FirstItem.column_names.sort.should == ['_id', '_type', 'first_only', 'for_all']
      EmbeddedDocuments::SecondItem.column_names.sort.should == ['_id', '_type', 'for_all', 'second_only']
    end

    it "should alias new to new_record?" do
      instance = EmbeddedDocuments::Item.new
      instance.new_record?.should == instance.new?
    end
  end
end
