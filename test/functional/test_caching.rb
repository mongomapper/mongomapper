require 'test_helper'

class CachingTest < Test::Unit::TestCase
  context "Caching" do
    setup do
      @klass = Class.new do
        extend MongoMapper::Plugins
        plugin MongoMapper::Plugins::Caching
      end
      @klass.stubs(:name).returns('Post')
      @klass.any_instance.stubs(:[]).returns(nil)
      @klass.any_instance.stubs(:[]=).returns(nil)
    end

    context "new" do
      setup do
        @doc = @klass.new
        @doc.stubs(:new?).returns(true)
      end

      should "be class/new" do
        @doc.cache_key.should == 'Post/new'
      end

      should "work with suffix" do
        @doc.cache_key(:foo).should == 'Post/new/foo'
      end
    end

    context "not new" do
      setup do
        @object_id = BSON::ObjectID.new
        @doc = @klass.new
        @doc.stubs(:new?).returns(false)
        @doc.stubs(:id).returns(@object_id)
      end

      context "with updated_at" do
        setup do
          time = Time.utc(2010, 6, 20, 8, 10, 7)
          @doc.expects(:[]).with(:updated_at).returns(time)
        end

        should "be class/id-timestamp" do
          @doc.cache_key.should == "Post/#{@object_id}-20100620081007"
        end

        should "work with suffix" do
          @doc.cache_key(:foo).should == "Post/#{@object_id}-20100620081007/foo"
        end
      end

      context "without updated_at" do
        should "be class/id" do
          @doc.cache_key.should == "Post/#{@object_id}"
        end

        should "work with suffix" do
          @doc.cache_key(:foo).should == "Post/#{@object_id}/foo"
        end
      end
    end
  end
end