require 'pathname'
require 'rubygems'

gem 'activesupport'
gem 'mongodb-mongo', '0.9'
gem 'jnunemaker-validatable', '1.7.1'

require 'activesupport'
require 'mongo'
require 'validatable'

if RUBY_VERSION.to_f == 1.8
  class BlankSlate #:nodoc:
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval/ }
  end
else
  class BlankSlate < BasicObject; end
end

dir = Pathname(__FILE__).dirname.expand_path + 'mongomapper'

require dir + 'callbacks'
require dir + 'finder_options'
require dir + 'key'
require dir + 'observing'
require dir + 'pagination'
require dir + 'rails_compatibility'
require dir + 'save_with_validation'
require dir + 'serialization'
require dir + 'validations'

require dir + 'associations/proxy'
require dir + 'associations/array_proxy'
require dir + 'associations/base'
require dir + 'associations/has_many_proxy'
require dir + 'associations/has_many_embedded_proxy'
require dir + 'associations/belongs_to_proxy'
require dir + 'associations/polymorphic_belongs_to_proxy'
require dir + 'associations'

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
