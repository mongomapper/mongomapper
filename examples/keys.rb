$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document

  key :first_name,  String, :required => true
  key :last_name,   String, :required => true
  key :token,       String, :default => lambda { 'some random string' }
  key :age,         Integer
  key :skills,      Array
  key :friend_ids,  Array, :typecast => 'ObjectId'
  timestamps!
end
User.collection.remove # empties collection

john = User.create({
  :first_name => 'John',
  :last_name  => 'Nunemaker',
  :age        => 28,
  :skills     => ['ruby', 'mongo', 'javascript'],
}) 

steve = User.create({
  :first_name => 'Steve',
  :last_name  => 'Smith',
  :age        => 29,
  :skills     => ['html', 'css', 'javascript', 'design'],
})

john.friend_ids << steve.id.to_s # will get typecast to ObjectId
john.save

pp john