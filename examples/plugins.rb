$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

# To create your own plugin, just create a module.
module FooPlugin
  
  # ClassMethods module will automatically get extended
  module ClassMethods
    def foo
      'Foo class method!'
    end
  end

  # InstanceMethods module will automatically get included
  module InstanceMethods
    def foo
      'Foo instance method!'
    end
  end

  # If present, configure method will be called and passed the 
  # model as an argument. Feel free to class_eval or add keys.
  # if method is not present, it doesn't call it.
  def self.configure(model)
    puts "Configuring #{model}..."
    model.key :foo, String
  end

end

class User
  include MongoMapper::Document
  plugin FooPlugin
end

puts User.foo
puts User.new.foo
puts User.key?(:foo)