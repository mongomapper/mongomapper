require 'pathname'
require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo'
gem 'jnunemaker-validatable'

require 'activesupport'
require 'mongo'
require 'validatable'

require 'mongo_mapper/validation'
require 'mongo_mapper/sub_document'
require 'mongo_mapper/document'
require 'mongo_mapper/key'
require 'mongo_mapper/finder_options'

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