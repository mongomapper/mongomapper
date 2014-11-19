require 'spec_helper'

class FakeNilProxy < MongoMapper::Plugins::Associations::Proxy
  def find_target; nil end
end

class FakeBlankProxy < MongoMapper::Plugins::Associations::Proxy
  def find_target; '' end
end

class FakeNumberProxy < MongoMapper::Plugins::Associations::Proxy
  def find_target; 17 end
end

class FakeProxy < MongoMapper::Plugins::Associations::Proxy
  def find_target; [1, 2] end
end

describe "Proxy" do
  before do
    @owner = double('owner')
    @owner.stub(:new?).and_return(false)
    @association = double('association')
    @association.stub(:options).and_return({:extend => []})

    @proxy       = FakeProxy.new(@owner, @association)
    @nil_proxy   = FakeNilProxy.new(@owner, @association)
    @blank_proxy = FakeBlankProxy.new(@owner, @association)
  end

  it "should set target to nil when reset is called" do
    @proxy.reset
    @proxy.target.should be_nil
  end

  it "should be able to inspect the proxy" do
    @proxy.inspect.should == '[1, 2]'
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

  it "should alias proxy target to target" do
    @proxy.proxy_target.should == @target
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
      lambda { @proxy.send(:gsub) }.should raise_error
    end

    it "should work if a proc is passed" do
      p = Proc.new {|x| x+1}
      @proxy.send(:collect, &p).should == [2,3]
    end
  end
end
