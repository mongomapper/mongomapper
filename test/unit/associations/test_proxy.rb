require 'test_helper'

class FakeProxy < MongoMapper::Associations::Proxy
  def find_target
    [1, 2]
  end
end

class ProxyTest < Test::Unit::TestCase
  should 'return true for === target' do
    Struct.new('Owner', :name)
    Struct.new('Association', :options)
    proxy = FakeProxy.new(Struct::Owner.new('owner'), Struct::Association.new({:extend => []}))
    proxy.should === Array
  end
end