require 'pathname'
require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo', '0.10.1'
gem 'jnunemaker-validatable', '1.7.2'

require 'activesupport'
require 'mongo'
require 'validatable'

class BasicObject #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
end unless defined?(BasicObject)

class Boolean
  def self.mm_typecast(value)
    ['true', 't', '1'].include?(value.to_s.downcase)
  end
end

class MongoID < XGen::Mongo::Driver::ObjectID
  def self.mm_typecast(value)
    begin
      if value.is_a?(XGen::Mongo::Driver::ObjectID)
        value
      else
        XGen::Mongo::Driver::ObjectID::from_string(value.to_s)
      end
    rescue => exception
      if exception.message == 'illegal ObjectID format'
        raise MongoMapper::DocumentNotFound
      else
        raise exception
      end
    end
  end
end

dir = Pathname(__FILE__).dirname.expand_path + 'mongomapper'

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

require dir + 'callbacks'
require dir + 'finder_options'
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
  class DocumentNotFound < StandardError; end
  class DocumentNotValid < StandardError
    def initialize(document)
      @document = document
      super("Validation failed: #{@document.errors.full_messages.join(", ")}")
    end
  end

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
