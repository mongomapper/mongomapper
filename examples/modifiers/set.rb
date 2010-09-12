$LOAD_PATH.unshift(File.expand_path('../../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  
  key :name, String
  key :tags, Array
end
User.collection.remove # empties collection

john = User.create(:name => 'John',  :tags => %w[ruby mongo], :age => 28)
bill = User.create(:name => 'Bill',  :tags => %w[ruby mongo], :age => 30)

User.set({:name => 'John'}, :tags => %[ruby])
pp john.reload

User.set(john.id, :tags => %w[ruby mongo])
pp john.reload

john.set(:tags => %w[something different])
pp john.reload
