require 'date'
require 'time'
require 'pathname'
require 'forwardable'

require 'rubygems'
gem 'activesupport'
require 'activesupport'
gem 'mongodb-mongo'
require 'mongo'

dir = Pathname(__FILE__).dirname.expand_path + 'mongo_mapper'
require dir + 'document'
require dir + 'key'

module MongoMapper  
  def self.connection
    @@connection ||= XGen::Mongo::Driver::Mongo.new
  end
  
  def self.connection=(new_connection)
    @@connection = new_connection
  end
  
  def self.default_database=(name)
    @@default_database = MongoMapper.connection.db(name)
  end
  
  def self.default_database
    @@default_database
  end
end