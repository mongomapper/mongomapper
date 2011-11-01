require 'spec_helper'

describe MongoMapper::Plugins::Associations::EmbeddedCollection do
  it "should set self to the root document on embedded documents" do
    pets = EDoc()
    document.many :pets, :class => pets

    doc = document.new(:pets => [{}])
    doc.pets.first._root_document.should == doc
  end
end
