require 'spec_helper'

describe "Safe" do
  context "A Document" do
    it "should default safe to off" do
      Doc().should_not be_safe
    end

    it "should allow turning safe on" do
      Doc() { safe }.should be_safe
    end

    context "inherited with safe setting on" do
      it "should set subclass safe setting on" do
        inherited = Class.new(Doc() { safe })
        inherited.should be_safe
        inherited.safe_options.should == true
      end

      it "should set subclass safe setting to same options hash as superclass" do
        inherited = Class.new(Doc() { safe(:j => true) })
        inherited.should be_safe
        inherited.safe_options.should == {:j => true}
      end
    end

    context "inherited with safe setting off" do
      it "should leave subclass safe setting off" do
        inherited = Class.new(Doc())
        inherited.should_not be_safe
      end
    end
  end

  context "An unsafe document" do
    before do
      @klass = Doc do
        safe(:w => 0)
      end
    end
    after { drop_indexes(@klass) }

    it "should not raise an error on duplicate IDs" do
      k = @klass.create
      expect { j = @klass.create(:_id => k.id) }.to_not raise_error
    end
  end

  context "A safe document" do
    before do
      @klass = Doc() do
        safe
      end
    end
    after { drop_indexes(@klass) }

    context "#save" do
      before do
        @klass.ensure_index :email, :unique => true
      end

      it "should raise an error on duplicate IDs" do
        k = @klass.create
        expect { j = @klass.create(:_id => k.id) }.to raise_error(Mongo::OperationFailure)
      end

      context "using safe setting from class" do
        it "should pass :w => 1 option to save" do
          instance = @klass.new(:email => 'john@doe.com')
          expect_any_instance_of(Mongo::Collection).to receive(:insert).once.with({'_id' => instance.id, 'email' => 'john@doe.com'}, {:w => 1})
          instance.save!
        end

        it "should work fine when all is well" do
          expect {
            @klass.new(:email => 'john@doe.com').save
          }.to_not raise_error
        end

        it "should raise error when operation fails" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save
            end
          }.to raise_error(Mongo::OperationFailure)
        end
      end

      context "overriding safe setting" do
        it "should raise error if safe is true" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => true)
            end
          }.to raise_error(Mongo::OperationFailure)
        end

        it "should not raise error if safe is false" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => false)
            end
          }.to_not raise_error
        end
      end
    end
  end

  context "a safe document with options hash" do
    before do
      @klass = Doc() do
        safe(:j => true)
      end
    end
    after { drop_indexes(@klass) }

    context "#save" do
      before do
        @klass.ensure_index :email, :unique => true
      end

      context "using safe setting from class" do
        it "should pass :safe => options_hash to save" do
          instance = @klass.new(:email => 'john@doe.com')
          expect_any_instance_of(Mongo::Collection).to receive(:insert).once.with({'_id' => instance.id, 'email' => 'john@doe.com'}, {:j => true})
          instance.save!
        end

        it "should work fine when all is well" do
          expect {
            @klass.new(:email => 'john@doe.com').save
          }.to_not raise_error
        end

        it "should raise error when operation fails" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save
            end
          }.to raise_error(Mongo::OperationFailure)
        end
      end

      context "overriding safe setting" do
        it "should raise error if safe is true" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => true)
            end
          }.to raise_error(Mongo::OperationFailure)
        end

        it "should not raise error if safe is false" do
          expect {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => false)
            end
          }.to_not raise_error
        end
      end
    end
  end
end