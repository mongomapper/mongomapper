require 'spec_helper'

describe "Caching" do
  before do
    @klass = Class.new do
      extend MongoMapper::Plugins
      plugin MongoMapper::Plugins::Caching
    end
    allow(@klass).to receive(:name).and_return('Post')
    allow_any_instance_of(@klass).to receive(:persisted?).and_return(true)
    allow_any_instance_of(@klass).to receive(:[]).and_return(nil)
    allow_any_instance_of(@klass).to receive(:[]=).and_return(nil)
  end

  context "new" do
    before do
      @doc = @klass.new
      allow(@doc).to receive(:persisted?).and_return(false)
    end

    it "should be class/new" do
      @doc.cache_key.should == 'Post/new'
    end

    it "should work with suffix" do
      @doc.cache_key(:foo).
        should == 'Post/new/foo'

      @doc.cache_key(:foo, :bar).
        should == 'Post/new/foo/bar'
    end
  end

  context "not new" do
    before do
      @object_id = BSON::ObjectId.new
      @doc = @klass.new
      allow(@doc).to receive(:persisted).and_return(true)
      allow(@doc).to receive(:id).and_return(@object_id)
    end

    context "with updated_at" do
      before do
        time = Time.utc(2010, 6, 20, 8, 10, 7)
        allow(@doc).to receive(:[]).with(:updated_at).and_return(time)
      end

      it "should be class/id-timestamp" do
        @doc.cache_key.should == "Post/#{@object_id}-20100620081007"
      end

      it "should work with suffix" do
        @doc.cache_key(:foo).
          should == "Post/#{@object_id}-20100620081007/foo"

        @doc.cache_key(:foo, :bar).
          should == "Post/#{@object_id}-20100620081007/foo/bar"
      end
    end

    context "without updated_at" do
      it "should be class/id" do
        @doc.cache_key.should == "Post/#{@object_id}"
      end

      it "should work with suffix" do
        @doc.cache_key(:foo).
          should == "Post/#{@object_id}/foo"

        @doc.cache_key(:foo, :bar, :baz).
          should == "Post/#{@object_id}/foo/bar/baz"
      end
    end
  end
end