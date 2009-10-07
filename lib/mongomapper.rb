require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo', '0.14.1'
gem 'jnunemaker-validatable', '1.7.2'

require 'activesupport'
require 'mongo'
require 'validatable'

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
  
  module Finders
    def dynamic_find(finder, args)
      attributes = {}
      find_options = args.extract_options!.deep_merge(:conditions => attributes)

      finder.attributes.each_with_index do |attr, index|
        attributes[attr] = args[index]
      end

      result = find(finder.finder, find_options)

      if result.nil?
        if finder.bang
          raise DocumentNotFound, "Couldn't find Document with #{attributes.inspect} in collection named #{collection.name}"
        end

        if finder.instantiator
          self.send(finder.instantiator, attributes)
        end
      else
        result
      end
    end
  end
end

require 'mongomapper/support'
require 'mongomapper/associations'
require 'mongomapper/associations/base'
require 'mongomapper/associations/proxy'
require 'mongomapper/associations/many_documents_proxy'
require 'mongomapper/associations/belongs_to_proxy'
require 'mongomapper/associations/belongs_to_polymorphic_proxy'
require 'mongomapper/associations/many_proxy'
require 'mongomapper/associations/many_polymorphic_proxy'
require 'mongomapper/associations/many_embedded_proxy'
require 'mongomapper/associations/many_embedded_polymorphic_proxy'
require 'mongomapper/associations/many_documents_as_proxy'
require 'mongomapper/callbacks'
require 'mongomapper/finder_options'
require 'mongomapper/dynamic_finder'
require 'mongomapper/key'
require 'mongomapper/observing'
require 'mongomapper/pagination'
require 'mongomapper/save_with_validation'
require 'mongomapper/serialization'
require 'mongomapper/validations'
require 'mongomapper/rails_compatibility/document'
require 'mongomapper/rails_compatibility/embedded_document'
require 'mongomapper/embedded_document'
require 'mongomapper/document'