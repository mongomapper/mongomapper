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
        inherited.safe_options.should == true
      end

      should "set subclass safe setting to same options hash as superclass" do
        inherited = Class.new(Doc() { safe(:j => true) })
        inherited.should be_safe
        inherited.safe_options.should == {:j => true}
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
        should "pass :safe => true option to save" do
          instance = @klass.new(:email => 'john@doe.com')
          Mongo::Collection.any_instance.expects(:save).once.with({'_id' => instance.id, 'email' => 'john@doe.com'}, {:safe => true})
          instance.save!
        end

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

  context "a safe document with options hash" do
    setup do
      @klass = Doc() do
        safe(:j => true)
      end
    end
    teardown { drop_indexes(@klass) }

    context "#save" do
      setup do
        @klass.ensure_index :email, :unique => true
      end

      context "using safe setting from class" do
        should "pass :safe => options_hash to save" do
          instance = @klass.new(:email => 'john@doe.com')
          Mongo::Collection.any_instance.expects(:save).once.with({'_id' => instance.id, 'email' => 'john@doe.com'}, {:safe => {:j => true}})
          instance.save!
        end

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