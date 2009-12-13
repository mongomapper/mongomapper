require 'test_helper'

class FakeProxy < MongoMapper::Associations::Proxy
  def find_target
    [1, 2]
  end
end

class ProxyTest < Test::Unit::TestCase
  def setup
    @owner = mock('owner')
    @association = mock('association', :options => {:extend => []})
  end
  
  should 'return true for === target' do
    proxy = FakeProxy.new(@owner, @association)
    proxy.should === Array
  end
end