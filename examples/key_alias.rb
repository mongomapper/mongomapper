$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  key :email_address, String, :alias => :e
  key :hate_to_store_this_long_key_for_each_document, String, :alias => :'l'
end

user = User.create(:hate_to_store_this_long_key_for_each_document => "tiny")
puts MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first

user.update_attribute(:email_address, 'ILoveSmallDB@gmail.com')
puts MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first

u = User.find(user.id)
puts "email address is: #{u.email_address}"
puts "long-key is: #{u.hate_to_store_this_long_key_for_each_document}"
puts "obj inspect looks like: #{u.inspect}"
puts "raw mongo looks like:   #{MongoMapper.connection['testing']['users'].find({"_id" => user.id}).first}"