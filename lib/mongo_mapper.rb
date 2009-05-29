require 'pathname'
require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo'
gem 'jnunemaker-validatable'

require 'activesupport'
require 'mongo'
require 'validatable'

dir = Pathname(__FILE__).dirname.expand_path + 'mongo_mapper'
require dir + 'validation'
require dir + 'document'
require dir + 'sub_document'
require dir + 'key'
require dir + 'finder_options'

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
  
  def self.subdocuments
    @@subdocuments ||= []
  end
  
  def self.add_subdocument(new_subdoc)
    subdocuments << new_subdoc
    subdocuments.uniq!
  end
end