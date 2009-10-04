require 'pathname'
require 'pp'
require 'rubygems'
require 'shoulda'

gem 'mocha', '0.9.4'
gem 'jnunemaker-matchy', '0.4.0'

require 'matchy'
require 'mocha'
require 'custom_matchers'

$LOAD_PATH.unshift(File.dirname(__FILE__))
dir = (Pathname(__FILE__).dirname +  '..' + 'lib').expand_path
require dir + 'mongomapper'

class Test::Unit::TestCase
  include CustomMatchers
  
  def clear_all_collections
    MongoMapper::Document.descendants.map { |d| d.collection.clear }
  end
end

DefaultDatabase = 'test' unless defined?(DefaultDatabase)
AlternateDatabase = 'test2' unless defined?(AlternateDatabase)

MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017)
MongoMapper.database = DefaultDatabase