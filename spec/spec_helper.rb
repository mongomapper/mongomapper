$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler/setup'
require 'fileutils'
require 'timecop'
require 'coveralls'
Coveralls.wear!

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'mongo_mapper'

def Doc(name='Class', &block)
  klass = Class.new
  klass.class_eval do
    include MongoMapper::Document

    if name
      class_eval "def self.name; '#{name}' end"
      class_eval "def self.to_s; '#{name}' end"
    else
      set_collection_name :test
    end
  end

  klass.class_eval(&block) if block_given?
  klass.collection.remove
  klass
end

def EDoc(name='Class', &block)
  klass = Class.new do
    include MongoMapper::EmbeddedDocument

    if name
      class_eval "def self.name; '#{name}' end"
      class_eval "def self.to_s; '#{name}' end"
    end
  end

  klass.class_eval(&block) if block_given?
  klass
end

def drop_indexes(klass)
  klass.collection.drop_indexes if klass.database.collection_names.include?(klass.collection.name)
end

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
logger = Logger.new(log_dir + '/test.log')

MongoMapper.connection = Mongo::MongoClient.new('127.0.0.1', 27017, :logger => logger)
MongoMapper.database = "test"
MongoMapper.database.collections.each { |c| c.drop_indexes }
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.around(:each, :without_connection) do |example|
    old, MongoMapper.connection = MongoMapper.connection, nil
    example.run
    MongoMapper.connection = old
  end
end

