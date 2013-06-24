require 'spec_helper'

describe "Clone" do
  context "Document" do
    before do
      @document = Doc()
      @embedded = EDoc()
      @document.many :widgets, :class => @embedded
      @tags = ['red', 'green', 'blue']
      @doc = @document.create({
        :name    => "foo",
        :age     => 27,
        :tags    => @tags,
        :widgets => [@embedded.new, @embedded.new],
      })
    end

    context "#clone" do
      it "should be new" do
        @doc.clone.should be_new
      end

      it "should copy the attributes" do
        clone = @doc.clone
        clone.name.should == "foo"
        clone.age.should == 27
      end

      it "should clone duplicable attributes" do
        @doc.clone.tags.should_not equal(@tags)
      end

      it "should clone many embedded documents" do
        @doc.clone.widgets.object_id.should_not equal(@doc.widgets.object_id)
      end

      it "should not be destroyed" do
        @doc.destroy
        @doc.clone.should_not be_destroyed
      end

      it "should generate a new id" do
        @doc.clone.id.should_not be_nil
        @doc.clone.id.should_not equal(@doc.id)
      end
    end
  end

  context "EmbeddedDocument" do
    before do
      @document = EDoc do
        key :name, String
        key :age, Integer
      end
    end

    context "#clone" do
      it "should regenerate the id" do
        doc = @document.new(:name => "foo", :age => 27)
        doc_id = doc.id
        clone = doc.clone
        clone_id = clone.id
        clone_id.should_not == doc_id
      end

      it "should copy the attributes" do
        doc = @document.new(:name => "foo", :age => 27)
        clone = doc.clone
        clone.name.should == "foo"
        clone.age.should == 27
      end
    end
  end
end