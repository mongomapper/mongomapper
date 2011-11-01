require 'spec_helper'

describe MongoMapper::Plugins::Equality do
  let(:oid) { BSON::ObjectId.new }

  context "Case equality" do
    before do
      @klass = Class.new do
        include MongoMapper::Plugins::Equality
      end
      @subklass = Class.new(@klass)

      @faker = Class.new do
        def initialize(faked)
          @faked = faked
        end

        def is_a?(klass)
          @faked.is_a? klass
        end
      end
    end

    it "should work with regular instance" do
      @klass.should === @klass.new
    end

    it "should work with instances of subclasses" do
      @klass.should === @subklass.new
    end

    it "should work with a faker class" do
      @klass.should === @faker.new(@klass.new)
    end

    it "should not work with other instances" do
      @klass.should_not === 1
    end
  end

  it "should delegate hash to _id" do
    doc = document.new
    doc.hash.should == doc._id.hash
  end

  it "should delegate eql to ==" do
    doc = document.new
    other = document.new
    doc.eql?(other).should == (doc == other)
    doc.eql?(doc).should == (doc == doc)
  end

  it "should know if same object as another" do
    doc = document.new
    doc.should equal(doc)
    doc.should_not equal(document.new)
  end

  it "should allow set operations on array of documents" do
    document.key :parent_id, ObjectId
    document.belongs_to :parent, :class => document

    parent = document.create
    child = document.create(:parent => parent)

    ([child.parent] & [parent]).should == [parent]
  end

  it "should be equal if id and class are the same" do
    (document.new('_id' => oid) == document.new('_id' => oid)).should be(true)
  end

  it "should not be equal if class same but id different" do
    (document.new('_id' => oid) == document.new('_id' => BSON::ObjectId.new)).should be(false)
  end

  it "should not be equal if id same but class different" do
    another_document = Doc()
    (document.new('_id' => oid) == another_document.new('_id' => oid)).should be(false)
  end
end
