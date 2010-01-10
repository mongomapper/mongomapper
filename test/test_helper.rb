require File.expand_path(File.dirname(__FILE__) + '/../lib/mongo_mapper')

gem 'jnunemaker-matchy', '0.4.0'
gem 'shoulda', '2.10.2'
gem 'timecop', '0.3.1'
gem 'mocha', '0.9.8'

require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'

require 'support/custom_matchers'
require 'support/timing'

class Test::Unit::TestCase
  include CustomMatchers
  
  cattr_accessor :mm_document_count
  self.mm_document_count = 0
  
  def Doc(name=nil, &block)
    Test::Unit::TestCase.mm_document_count += 1
    
    klass = Class.new do
      include MongoMapper::Document
      set_collection_name "test#{rand(20)}"
      
      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
      
      class_eval(&block) if block_given?
    end
    klass.collection.remove
    klass
  end
  
  def EDoc(name=nil, &block)
    Class.new do
      include MongoMapper::EmbeddedDocument
      
      if name
        class_eval "def self.name; '#{name}' end"
        class_eval "def self.to_s; '#{name}' end"
      end
      
      class_eval(&block) if block_given?
    end
  end
end

test_dir = File.expand_path(File.dirname(__FILE__) + '/../tmp')
FileUtils.mkdir_p(test_dir) unless File.exist?(test_dir)

MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017, {
  :logger => Logger.new(test_dir + '/test.log')
})
MongoMapper.database = 'test'