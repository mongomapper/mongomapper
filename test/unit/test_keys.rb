require 'test_helper'
require 'models'

class KeyTest < Test::Unit::TestCase
  context ".new with no id and _id of type integer" do
    should "not error" do
      lambda {
        klass = Doc() do
          key :_id, Integer
        end
        # No sensible default id for integer, people better pass them in if they user this
        silence_stderr { klass.new.id.should be_nil }
      }.should_not raise_error
    end
  end

  context ".key?(:symbol)" do
    should "be true if document has key" do
      Address.key?(:city).should be_true
    end

    should "be false if document does not have key" do
      Address.key?(:foo).should be_false
    end
  end

  context ".key?('string')" do
    should "be true if document has key" do
      Address.key?('city').should be_true
    end

    should "be false if document does not have key" do
      Address.key?('foo').should be_false
    end
  end

  context ".new (from database)" do
    setup do
      @klass = Doc do
        key :user, Hash

        def user=(user)
          super(:id => user.id, :name => user.name)
        end
      end

      user_class = Struct.new(:id, :name)
      @klass.create(:user => user_class.new(1, 'John Nunemaker'))
    end

    should "use []= for keys instead of public writer" do
      assert_nothing_raised do
        doc = @klass.first
        doc.user['id'].should   == 1
        doc.user['name'].should == 'John Nunemaker'
      end
    end
  end

  context ".load" do
    should "return nil if argument is nil" do
      Doc().load(nil).should be_nil
    end
  end

  context "default values" do
    setup do
      @klass = Doc do
        key :value, Integer, :default => 1
      end
    end

    should "initialize default value" do
      @klass.new.value.should == 1
    end

    should "allow overriding default value" do
      @klass.new(:value => 2).value.should == 2
    end

    should "allow re-setting a value that is defaulted" do
      instance = @klass.new
      instance.value = 2
      instance.value.should == 2
      instance.value = nil
      instance.value.should == nil
    end
  end
end # KeyTest
