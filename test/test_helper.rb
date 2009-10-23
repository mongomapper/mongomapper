require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib/mongo_mapper'))

gem 'jnunemaker-matchy', '0.4.0'
gem 'shoulda', '2.10.2'
gem 'timecop', '0.3.1'
gem 'mocha', '0.9.4'

require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'

require 'support/custom_matchers'
require 'support/test_timing'

class Test::Unit::TestCase
  include CustomMatchers
  
  def clear_all_collections
    MongoMapper::Document.descendants.map { |d| d.collection.clear }
  end
end

DefaultDatabase = 'test' unless defined?(DefaultDatabase)
AlternateDatabase = 'test2' unless defined?(AlternateDatabase)

test_dir = File.expand_path(File.dirname(__FILE__) + '/../tmp')
FileUtils.mkdir_p(test_dir) unless File.exist?(test_dir)

MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => Logger.new(test_dir + '/test.log'))
MongoMapper.database = DefaultDatabase