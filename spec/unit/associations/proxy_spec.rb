require 'spec_helper'

class FakeNilProxy < MongoMapper::Plugins::Associations::Proxy
  def load_target; @target ||= nil end
end

class FakeBlankProxy < MongoMapper::Plugins::Associations::Proxy
  def load_target; @target ||= '' end
end

class FakeNumberProxy < MongoMapper::Plugins::Associations::Proxy
  def load_target; @target ||= 17 end
end

class FakeProxy < MongoMapper::Plugins::Associations::Proxy
  def load_target; @target ||= [1, 2] end
end

describe "Proxy" do
  before do
    @owner = double('owner', :new? => false)
    @association = double('association', :options => {:extend => []})

    @proxy       = FakeProxy.new(@owner, @association)
    @nil_proxy   = FakeNilProxy.new(@owner, @association)
    @blank_proxy = FakeBlankProxy.new(@owner, @association)
  end

  it "should set target to nil when reset is called" do
    @proxy.reset
    @proxy.target.should be_nil
  end

  it "should be able to inspect the proxy" do
    @proxy.inspect.should == "#<FakeProxy:#{@proxy.object_id} [1, 2]>"
  end

  context "nil?" do
    it "should be true if nil" do
      @nil_proxy.nil?.should be_truthy
    end

    it "should be false if not nil" do
      @proxy.nil?.should be_falsey
    end
  end

  context "blank?" do
    it "should be true if blank" do
      @blank_proxy.blank?.should be_truthy
      @nil_proxy.blank?.should be_truthy
    end

    it "should be false if not blank" do
      @proxy.blank?.should be_falsey
    end
  end

  context "present?" do
    it "should be true if present" do
      @proxy.present?.should be_truthy
    end

    it "should be false if not present" do
      @blank_proxy.present?.should be_falsey
      @nil_proxy.present?.should be_falsey
    end
  end

  it "should delegate respond_to? to target" do
    @proxy.respond_to?(:each).should be_truthy
    @proxy.respond_to?(:size).should be_truthy
    @proxy.respond_to?(:gsub).should be_falsey
  end

  it "should alias proxy owner to owner" do
    @proxy.proxy_owner.should == @owner
  end

  context "send" do
    it "should work if proxy responds to method" do
      @proxy.send(:reset)
      @proxy.target.should be_nil
    end

    it "should work if the target responds to the method" do
      @proxy.send(:size).should == 2
    end

    it "should not work if neither the proxy or target respond to method" do
      lambda { @proxy.send(:gsub) }.should raise_error(NoMethodError)
    end

    it "should work if a proc is passed" do
      p = Proc.new {|x| x+1}
      @proxy.send(:collect, &p).should == [2,3]
    end

    it "should not respond to private method" do
      @proxy.reload # To load @proxy.target
      @proxy.target.extend(Module.new do
        private

          def private_foo
          end
      end)

      lambda { @proxy.private_foo }.should raise_error(NoMethodError, /private method ['`]private_foo' called/)
    end
  end

  context "hash" do
    it "should return the same value for the same proxy" do
      proxy_a = FakeProxy.new(@owner, @association)
      proxy_b = FakeProxy.new(@owner, @association)

      proxy_a.hash.should == proxy_b.hash
    end

    it "should return different values for different proxies" do
      @proxy.hash.should_not == @nil_proxy.hash
    end
  end
end
