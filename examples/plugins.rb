$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

# To create your own plugin, just create a module that
# extends ActiveSupport::Concern.
module FooPlugin
  extend ActiveSupport::Concern

  # ClassMethods module will automatically get extended
  module ClassMethods
    def foo
      'Foo class method!'
    end
  end

  def foo
    'Foo instance method!'
  end

  # Any configuration can be done in the #included block, which gets
  # class evaled. Feel free to add keys, validations, or anything else.
  included do
    puts "Configuring #{self}..."
    key :foo, String
  end
end

class User
  include MongoMapper::Document
  plugin FooPlugin
end

puts User.foo
puts User.new.foo
puts User.key?(:foo)