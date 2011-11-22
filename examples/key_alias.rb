$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  key :email_address, String, :alias => :e
  key :hate_to_store_this_long_key_for_each_document, String, :alias => :'l'
end

# create, update objects like normal
user = User.create(:hate_to_store_this_long_key_for_each_document => "tiny")
puts MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first

user.update_attribute(:email_address, 'IHeartSmallDB@gmail.com')
puts MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first

# query like normal, object returned will respond to human readable keys
u = User.find(user.id)
puts "email address is: #{u.email_address}"
puts "long-key is: #{u.hate_to_store_this_long_key_for_each_document}"
puts "obj inspect looks like: #{u.inspect}"
puts "raw mongo looks like:   #{MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first}"

#dynamic finders work as expected
u2 = User.find_by_email_address('IHeartSmallDB@gmail.com')
puts u2.inspect