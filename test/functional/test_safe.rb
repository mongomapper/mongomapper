require 'test_helper'

class SafeTest < Test::Unit::TestCase
  context "A Document" do
    should "default safe to off" do
      Doc().should_not be_safe
    end

    should "allow turning safe on" do
      Doc() { safe }.should be_safe
    end

    context "inherited with safe setting on" do
      should "set subclass safe setting on" do
        inherited = Class.new(Doc() { safe })
        inherited.should be_safe
      end
    end

    context "inherited with safe setting off" do
      should "leave subclass safe setting off" do
        inherited = Class.new(Doc())
        inherited.should_not be_safe
      end
    end
  end

  context "A safe document" do
    setup do
      @klass = Doc() do
        safe
      end
    end
    teardown { drop_indexes(@klass) }

    context "#save" do
      setup do
        @klass.ensure_index :email, :unique => true
      end

      context "using safe setting from class" do
        should "work fine when all is well" do
          assert_nothing_raised do
            @klass.new(:email => 'john@doe.com').save
          end
        end

        should "raise error when operation fails" do
          assert_raises(Mongo::OperationFailure) do
            2.times do
              @klass.new(:email => 'john@doe.com').save
            end
          end
        end
      end

      context "overriding safe setting" do
        should "raise error if safe is true" do
          assert_raises(Mongo::OperationFailure) do
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => true)
            end
          end
        end

        should "not raise error if safe is false" do
          assert_nothing_raised do
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => false)
            end
          end
        end
      end
    end
  end
end