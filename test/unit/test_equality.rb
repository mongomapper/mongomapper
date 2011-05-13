require 'test_helper'

class Equality
  include MongoMapper::Plugins::Equality
end

class Equality2 < Equality; end

class Faker
  def initialize(faked)
    @faked = faked
  end

  def is_a?(klass)
    @faked.is_a? klass
  end
end

class EqualityTest < Test::Unit::TestCase
  context "Case equality" do
    should "work with regular instance" do
      Equality.should === Equality.new
    end

    should "work with instances of subclasses" do
      Equality.should === Equality2.new
    end

    should "work with a faker class" do
      Equality.should === Faker.new(Equality.new)
    end

    should "not work with other instances" do
      Equality.should_not === 1
    end
  end
end
