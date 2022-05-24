$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler/setup'

# workaround for https://github.com/jruby/jruby/issues/6547
if RUBY_PLATFORM == 'java'
  require 'i18n/backend'
  require 'i18n/backend/simple'
end

Bundler.require(:default)
require 'fileutils'
require 'timecop'
require "generator_spec/test_case"

if RUBY_ENGINE == "ruby" && RUBY_VERSION >= '2.3'
  require 'byebug'
end

if RUBY_PLATFORM != "java"
  if ENV['GITHUB_ACTIONS']
    require 'coveralls'
    Coveralls.wear!
  elsif ENV['COVERAGE'] && RUBY_VERSION > "1.8"
    require 'simplecov'
    SimpleCov.start do
      add_filter 'spec'
      add_group 'Core',         'lib/mongo_mapper'
      add_group 'Rails',        'lib/rails'
      add_group 'Extensions',   'lib/mongo_mapper/extensions'
      add_group 'Plugins',      'lib/mongo_mapper/plugins'
      add_group 'Associations', 'lib/mongo_mapper/plugins/associations'
    end
  end
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
  klass.collection.drop
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
  klass.collection.indexes.drop_all if klass.database.collection_names.include?(klass.collection.name)
end

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
logger = Logger.new(log_dir + '/test.log')

Mongo::Logger.logger = logger

MongoMapper.connection = Mongo::Client.new(['127.0.0.1:27017'], :database => 'test')
MongoMapper.database.collections.each { |c| c.indexes.drop_all }
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.expect_with :rspec do |c|
    c.syntax = :should
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  config.around(:each, :without_connection) do |example|
    old, MongoMapper.connection = MongoMapper.connection, nil
    example.run
    MongoMapper.connection = old
  end

  def suppress_stderr
    begin
      original_stderr = $stderr.clone
      $stderr.reopen(File.new('/dev/null', 'w'))
      retval = yield
    rescue Exception => e
      $stderr.reopen(original_stderr)
      raise e
    ensure
      $stderr.reopen(original_stderr)
    end
    retval
  end
end
