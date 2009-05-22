$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'mongo_mapper'

require 'test/unit/assertions'

World(Test::Unit::Assertions)
