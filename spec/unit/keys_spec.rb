require 'spec_helper'


describe "Key" do
  context ".new with no id and _id of type integer" do
    it "should not error" do
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
    it "should be true if document has key" do
      Address.key?(:city).should be_truthy
    end

    it "should be false if document does not have key" do
      Address.key?(:foo).should be_falsey
    end
  end

  context "#assign" do
    it "should raise a deprecation warning" do
      klass = Doc() do
        key :_id, Integer
      end
      doc = klass.new
      doc.should_receive(:warn).once
      doc.assign({:x => :y})
    end
  end

  # TODO: Are these methods deprecated?
  context "#embedded and #non_embedded_keys" do
    EmbeddableThingie = EDoc {
      key :whiz, String
    }

    let(:klass) do
      Doc do
        key :foo, String
        key :embeddable_thingie, EmbeddableThingie
      end
    end

    it "should get non-embeddable keys" do
      klass.new.non_embedded_keys.map(&:name).should =~ %w(_id foo)
    end

    it "should get embeddable keys" do
      klass.new.embedded_keys.map(&:name).should == %w(embeddable_thingie)
    end
  end

  context ".key?('string')" do
    it "should be true if document has key" do
      Address.key?('city').should be_truthy
    end

    it "should be false if document does not have key" do
      Address.key?('foo').should be_falsey
    end
  end

  context ".new (from database)" do
    before do
      @klass = Doc do
        key :user, Hash

        def user=(user)
          super(:id => user.id, :name => user.name)
        end
      end

      user_class = Struct.new(:id, :name)
      @klass.create(:user => user_class.new(1, 'John Nunemaker'))
    end

    it "should use []= for keys instead of public writer" do
      expect {
        doc = @klass.first
        doc.user['id'].should   == 1
        doc.user['name'].should == 'John Nunemaker'
      }.to_not raise_error
    end
  end

  context ".load" do
    it "should return nil if argument is nil" do
      Doc().load(nil).should be_nil
    end
  end

  context "default values" do
    before do
      @klass = Doc do
        key :value, Integer, :default => 1
      end
    end

    it "should initialize default value" do
      @klass.new.value.should == 1
    end

    it "should allow overriding default value" do
      @klass.new(:value => 2).value.should == 2
    end

    it "should allow re-setting a value that is defaulted" do
      instance = @klass.new
      instance.value = 2
      instance.value.should == 2
      instance.value = nil
      instance.value.should == nil
    end

    context "for _id" do
      before do
        @klass.class_eval do
          key :_id, Integer, :default => lambda { 12345 }
        end
      end

      it "should work" do
        @klass.new._id.should == 12345
      end
    end
  end

  context "when loading from the database" do
    it "should not set default values for keys that already exist" do
      counter = 0
      instance = nil

      klass = Doc do
        key :value, Integer, :default => lambda { counter += 1 }
      end

      expect { instance = klass.create }.to change { counter }.by(1)
      expect {
        instance.reload.value.should == 1

        instance.value = 10
        instance.save

        instance.reload.value.should == 10
      }.to_not change { counter }
    end
  end
end # KeyTest
