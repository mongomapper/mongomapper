# if Gem is defined i'll assume you are using rubygems and lock specific versions
# call me crazy but a plain old require will just get the latest version you have installed
# so i want to make sure that if you are using gems you do in fact have the correct versions
# if there is a better way to do this, please enlighten me!
if self.class.const_defined?(:Gem)
  gem 'activesupport', '>= 2.3'
  gem 'mongo', '0.18.1'
  gem 'jnunemaker-validatable', '1.8.1'
end

require 'active_support'
require 'mongo'
require 'validatable'

module MongoMapper
  # generic MM error
  class MongoMapperError < StandardError; end
  
  # raised when key expected to exist but not found
  class KeyNotFound < MongoMapperError; end
  
  # raised when document expected but not found
  class DocumentNotFound < MongoMapperError; end
  
  # raised when document not valid and using !
  class DocumentNotValid < MongoMapperError
    def initialize(document)
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end
  
  # @api public
  def self.connection
    @@connection ||= Mongo::Connection.new
  end
  
  # @api public
  def self.connection=(new_connection)
    @@connection = new_connection
  end
  
  # @api public
  def self.logger
    connection.logger
  end
  
  # @api public
  def self.database=(name)
    @@database = nil
    @@database_name = name
  end
  
  # @api public
  def self.database
    if @@database_name.blank?
      raise 'You forgot to set the default database name: MongoMapper.database = "foobar"'
    end
    
    @@database ||= MongoMapper.connection.db(@@database_name)
  end
  
  # @api private
  def self.ensured_indexes
    @@ensured_indexes ||= []
  end
  
  # @api private
  def self.ensure_index(klass, keys, options={})
    ensured_indexes << {:klass => klass, :keys => keys, :options => options}
  end
  
  # @api public
  def self.ensure_indexes!
    ensured_indexes.each do |index|
      unique = index[:options].delete(:unique)
      index[:klass].collection.create_index(index[:keys], unique)
    end
  end
  
  # @api private
  def self.use_time_zone?
    Time.respond_to?(:zone) && Time.zone ? true : false
  end
  
  # @api private
  def self.time_class
    use_time_zone? ? Time.zone : Time
  end
  
  # @api private
  def self.normalize_object_id(value)
    value.is_a?(String) ? Mongo::ObjectID.from_string(value) : value
  end
end

require 'mongo_mapper/support'
require 'mongo_mapper/callbacks'
require 'mongo_mapper/finder_options'
require 'mongo_mapper/dirty'
require 'mongo_mapper/dynamic_finder'
require 'mongo_mapper/key'
require 'mongo_mapper/observing'
require 'mongo_mapper/pagination'
require 'mongo_mapper/serialization'
require 'mongo_mapper/validations'
require 'mongo_mapper/rails_compatibility/document'
require 'mongo_mapper/rails_compatibility/embedded_document'
require 'mongo_mapper/embedded_document'
require 'mongo_mapper/document'
require 'mongo_mapper/associations'
require 'mongo_mapper/associations/base'
require 'mongo_mapper/associations/proxy'
require 'mongo_mapper/associations/collection'
require 'mongo_mapper/associations/many_documents_proxy'
require 'mongo_mapper/associations/belongs_to_proxy'
require 'mongo_mapper/associations/belongs_to_polymorphic_proxy'
require 'mongo_mapper/associations/many_polymorphic_proxy'
require 'mongo_mapper/associations/many_embedded_proxy'
require 'mongo_mapper/associations/many_embedded_polymorphic_proxy'
require 'mongo_mapper/associations/many_documents_as_proxy'
