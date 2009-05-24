require 'rubygems'
require 'test/unit'
require 'shoulda'
gem 'jnunemaker-matchy', '0.4.0'
require 'matchy'
gem 'mocha'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongo_mapper'

class Test::Unit::TestCase
end

DefaultDatabase = 'test'
AlternateDatabase = 'test2'

MongoMapper.database = DefaultDatabase