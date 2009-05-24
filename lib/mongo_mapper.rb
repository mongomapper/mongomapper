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
  class DocumentNotFound < StandardError; end
  
  def self.connection
    @@connection ||= XGen::Mongo::Driver::Mongo.new
  end
  
  def self.connection=(new_connection)
    @@connection = new_connection
  end
  
  def self.database=(name)
    @@database = MongoMapper.connection.db(name)
  end
  
  def self.database
    @@database
  end
end