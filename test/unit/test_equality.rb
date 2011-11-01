require 'test_helper'

class EqualityTest < Test::Unit::TestCase
  context "Case equality" do
    setup do
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

    should "work with regular instance" do
      @klass.should === @klass.new
    end

    should "work with instances of subclasses" do
      @klass.should === @subklass.new
    end

    should "work with a faker class" do
      @klass.should === @faker.new(@klass.new)
    end

    should "not work with other instances" do
      @klass.should_not === 1
    end
  end
end
