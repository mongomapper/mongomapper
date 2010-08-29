$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :name, String
end
User.delete_all

user = User.create(:name => 'John')

# User gets added to map on save
pp User.identity_map[user.id]

# Does not matter how you find user, it is always the same object until the identity map is cleared
puts "#{User.identity_map[user.id].object_id} == #{user.object_id}"
puts "#{User.find(user.id).object_id} == #{user.object_id}"
puts "#{User.all[0].object_id} == #{user.object_id}"

MongoMapper::Plugins::IdentityMap.clear
puts "#{User.find(user.id).object_id} != #{user.object_id}"

# User gets removed from map on destroy
user = User.create
user.destroy
puts "Should be nil: " + User.identity_map[user.id].inspect


