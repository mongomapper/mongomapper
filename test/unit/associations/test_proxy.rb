require 'test_helper'

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

class ProxyTest < Test::Unit::TestCase
  def setup
    @owner = mock('owner')
    @owner.stubs(:new?).returns(false)
    @association = mock('association')
    @association.stubs(:options).returns({:extend => []})

    @proxy       = FakeProxy.new(@owner, @association)
    @nil_proxy   = FakeNilProxy.new(@owner, @association)
    @blank_proxy = FakeBlankProxy.new(@owner, @association)
  end
  
  should 'return true for === target' do
    @proxy = FakeProxy.new(@owner, @association)
    @proxy.should === Array
  end
  
  should "set target to nil when reset is called" do
    @proxy.reset
    @proxy.target.should be_nil
  end
  
  should "be able to inspect the proxy" do
    @proxy.inspect.should == '[1, 2]'
  end
  
  context "nil?" do
    should "be true if nil" do
      @nil_proxy.nil?.should be_true
    end
    
    should "be false if not nil" do
      @proxy.nil?.should be_false
    end
  end
  
  context "blank?" do
    should "be true if blank" do
      @blank_proxy.blank?.should be_true
      @nil_proxy.blank?.should be_true
    end
    
    should "be false if not blank" do
      @proxy.blank?.should be_false
    end
  end
  
  context "present?" do
    should "be true if present" do
      @proxy.present?.should be_true
    end
    
    should "be false if not present" do
      @blank_proxy.present?.should be_false
      @nil_proxy.present?.should be_false
    end
  end
  
  should "delegate respond_to? to target" do
    @proxy.respond_to?(:each).should be_true
    @proxy.respond_to?(:size).should be_true
    @proxy.respond_to?(:gsub).should be_false
  end
  
  should "alias proxy owner to owner" do
    @proxy.proxy_owner.should == @owner
  end
  
  should "alias proxy target to target" do
    @proxy.proxy_target.should == @target
  end
  
  context "send" do
    should "work if proxy responds to method" do
      @proxy.send(:reset)
      @proxy.target.should be_nil
    end
    
    should "work if the target responds to the method" do
      @proxy.send(:size).should == 2
    end
    
    should "not work if neither the proxy or target respond to method" do
      lambda { @proxy.send(:gsub) }.should raise_error
    end
  end
end