require 'pp'
require 'rubygems'
require 'shoulda'
require 'activesupport'

gem 'timecop', '0.3.1'
require 'timecop'

gem 'mocha', '0.9.4'
require 'mocha'

gem 'jnunemaker-matchy', '0.4.0'
require 'matchy'

require 'support/custom_matchers'
require 'support/test_timing'

require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib/mongo_mapper'))

class Test::Unit::TestCase
  include CustomMatchers
  
  def clear_all_collections
    MongoMapper::Document.descendants.map { |d| d.collection.clear }
  end
end

DefaultDatabase = 'test' unless defined?(DefaultDatabase)
AlternateDatabase = 'test2' unless defined?(AlternateDatabase)

logger = Logger.new(File.expand_path(File.dirname(__FILE__) + '/../tmp/test.log'))
MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => logger)
MongoMapper.database = DefaultDatabase