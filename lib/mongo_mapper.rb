require 'date'
require 'time'
require 'pathname'
require 'forwardable'

require 'rubygems'
gem 'activesupport'
require 'activesupport'

dir = Pathname(__FILE__).dirname.expand_path + 'mongo_mapper'
require dir + 'document'
require dir + 'key'

module MongoMapper; end