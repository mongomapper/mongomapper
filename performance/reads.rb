require 'perftools'
require 'pp'
require 'benchmark'
require 'rubygems'

# Script Brandon and I used to benchmark reads while improving performance.
# Included here for historical purposes.

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'mongo_mapper'

MongoMapper.database = 'testing'

class Site
  include MongoMapper::Document

  key :title, String
end
Site.collection.drop

site = Site.create(:title => 'Testing')

times = 1_000

driver_result = Benchmark.realtime {
  times.times{ Site.collection.find_one('_id' => site.id) }
}

mm_result = Benchmark.realtime {
  times.times{ Site.first('_id' => site.id) }
}

puts 'Collection#find_one', driver_result, 'Site.first', mm_result, 'Ratio', mm_result / driver_result

# PerfTools::CpuProfiler.start('prof_client') do
#   times.times{ Site.collection.find_one('_id' => site.id) }
# end

# PerfTools::CpuProfiler.start('prof_reads') do
#   times.times{ Site.find(site.id) }
# end

# system('pprof.rb --gif --ignore=Collection#find_one prof_reads > prof_reads.gif')
# system('open prof_reads.gif')