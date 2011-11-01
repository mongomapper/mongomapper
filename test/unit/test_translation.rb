require 'test_helper'

class TranslationTest < Test::Unit::TestCase
  should "translate add mongo_mapper translations" do
    I18n.translate("mongo_mapper.errors.messages.taken").should == "has already been taken"
  end

  should "set i18n_scope" do
    Doc().i18n_scope.should == :mongo_mapper
  end

  should "translate document attributes" do
    I18n.config.backend.store_translations(:en, :mongo_mapper => {:attributes => {:thing => {:foo => 'Bar'}}})
    doc = Doc('Thing') do
      key :foo, String
    end
    doc.human_attribute_name(:foo).should == 'Bar'
  end

  should "translate embedded document attributes" do
    I18n.config.backend.store_translations(:en, :mongo_mapper => {:attributes => {:thing => {:foo => 'Bar'}}})
    doc = EDoc('Thing') do
      key :foo, String
    end
    doc.human_attribute_name(:foo).should == 'Bar'
  end
end