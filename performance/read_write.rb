# The purpose of this is to check finding, initializing, 
# and creating objects (typecasting times/dates and booleans).

require 'pp'
require 'benchmark'
require 'rubygems'

# to test with slow version just do this:
# gem 'mongo_mapper', '0.6.10'
# and comment out this:
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'mongo_mapper'

MongoMapper.database = 'testing'
 
class Foo
  include MongoMapper::Document
  key :approved, Boolean
  key :count, Integer
  key :approved_at, Time
  key :expire_on, Date
  timestamps!
end
Foo.collection.remove

Benchmark.bm(5) do |x|
  ids = []
  x.report("write") do
    1000.times { |i| ids << Foo.create(:count => 0, :approved => true, :approved_at => Time.now, :expire_on => Date.today).id }
  end

  x.report("read ") do
    ids.each { |id| Foo.first(:id => id) }
  end
end

# I was get something like this on my puny macbook air:
#            user     system      total        real
# write  4.810000   0.090000   4.900000 (  5.039949)
# read   2.730000   0.070000   2.800000 (  2.990749)
#
#
# After these commits:
#
#   * http://github.com/jnunemaker/mongomapper/commit/e5091fa140d5fae2721017b53027092233694ee5
#   * http://github.com/jnunemaker/mongomapper/commit/c22bbde4fa1cfbc310d79cb0e50203310ffb03d1
#
# I'm now getting something like this:
#            user     system      total        real
# write  1.660000   0.050000   1.710000 (  1.752676)
# read   1.060000   0.050000   1.110000 (  1.263429)