require 'test_helper'

class CloneTest < Test::Unit::TestCase
  context "Document" do
    setup do
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
      should "be new" do
        @doc.clone.should be_new
      end

      should "copy the attributes" do
        clone = @doc.clone
        clone.name.should == "foo"
        clone.age.should == 27
      end

      should "clone duplicable attributes" do
        @doc.clone.tags.should_not equal(@tags)
      end

      should "clone many embedded documents" do
        @doc.clone.widgets.object_id.should_not equal(@doc.widgets.object_id)
      end

      should "not be destroyed" do
        @doc.destroy
        @doc.clone.should_not be_destroyed
      end
    end
  end

  context "EmbeddedDocument" do
    setup do
      @document = EDoc do
        key :name, String
        key :age, Integer
      end
    end

    context "#clone" do
      should "regenerate the id" do
        doc = @document.new(:name => "foo", :age => 27)
        doc_id = doc.id
        clone = doc.clone
        clone_id = clone.id
        clone_id.should_not == doc_id
      end

      should "copy the attributes" do
        doc = @document.new(:name => "foo", :age => 27)
        clone = doc.clone
        clone.name.should == "foo"
        clone.age.should == 27
      end
    end
  end
end