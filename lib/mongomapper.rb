require 'pathname'
require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo', '0.14.1'
gem 'jnunemaker-validatable', '1.7.2'

require 'activesupport'
require 'mongo'
require 'validatable'

dir = Pathname(__FILE__).dirname.expand_path + 'mongomapper'

require dir + 'support'

require dir + 'associations'
require dir + 'associations/base'

require dir + 'associations/proxy'
require dir + 'associations/many_documents_proxy'

require dir + 'associations/belongs_to_proxy'
require dir + 'associations/belongs_to_polymorphic_proxy'
require dir + 'associations/many_proxy'
require dir + 'associations/many_polymorphic_proxy'
require dir + 'associations/many_embedded_proxy'
require dir + 'associations/many_embedded_polymorphic_proxy'
require dir + 'associations/many_documents_as_proxy'

require dir + 'callbacks'
require dir + 'finder_options'
require dir + 'dynamic_finder'
require dir + 'key'
require dir + 'observing'
require dir + 'pagination'
require dir + 'save_with_validation'
require dir + 'serialization'
require dir + 'validations'

require dir + 'rails_compatibility/document'
require dir + 'rails_compatibility/embedded_document'

require dir + 'embedded_document'
require dir + 'document'

module MongoMapper
  DocumentNotFound  = Class.new(StandardError)
  
  DocumentNotValid  = Class.new(StandardError) do
    def initialize(document)
      @document = document
      super("Validation failed: #{@document.errors.full_messages.join(", ")}")
    end
  end
  
  def self.connection
    @@connection ||= Mongo::Connection.new
  end

  def self.connection=(new_connection)
    @@connection = new_connection
  end

  def self.database=(name)
    @@database = nil
    @@database_name = name
  end

  def self.database
    if @@database_name.blank?
      raise 'You forgot to set the default database name: MongoMapper.database = "foobar"'
    end
    
    @@database ||= MongoMapper.connection.db(@@database_name)
  end
end
