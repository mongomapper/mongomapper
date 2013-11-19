require 'spec_helper'

describe 'Mass assignment update protection' do
  before do
    @doc_class = Doc("Post")
  end

  it "should raise error when mass assign forbidden attributes" do
    forbidden_attributes = ProtectedParams.new title: "Fatastic Post"
    expect {
      @doc_class.new forbidden_attributes
    }.to raise_error(ActiveModel::ForbiddenAttributesError)
  end

  it "should accept permitted attributes for mass assignment" do
    permitted_attributes = ProtectedParams.new(title: "Fatastic Post").permit!
    expect {
      post = @doc_class.new permitted_attributes
    }.not_to raise_error
  end

  it "should work with regular hash for mass assignment" do
    post = @doc_class.new title: "Fatastic Post"

    expect(post.title).to eql("Fatastic Post")
  end
end
