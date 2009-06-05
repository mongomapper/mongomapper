require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo'
gem 'jnunemaker-validatable'

require 'activesupport'
require 'mongo'
require 'validatable'

require 'mongo_mapper/key'
require 'mongo_mapper/finder_options'
require 'mongo_mapper/save_with_validation'
require 'mongo_mapper/embedded_document'
require 'mongo_mapper/document'

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