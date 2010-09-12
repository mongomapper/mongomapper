$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  key :email, String
  key :admin, Boolean, :default => false

  # Only accessible or protected can be used, they cannot be used together
  attr_protected :admin
end

# protected are ignored on new/create/etc.
user = User.create(:email => 'IDontLowerCaseThings@gmail.com', :admin => true)
puts user.admin # false

# can be set using accessor
user.admin = true
user.save
puts user.admin # true
