require 'spec_helper'

describe "Equality" do
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
end
