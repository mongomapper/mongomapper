$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
end

# New Documents
puts User.new.cache_key     # User/new

# Created Documents
puts User.create.cache_key  # User/:id (ie: User/4c7a940cbcd1b3319b000003)

# With Suffix
puts User.create.cache_key(:foo) # User/:id/foo

# With Multiple Suffixes
puts User.create.cache_key(:foo, :bar, :baz) # User/:id/foo/bar/baz

# When updated_at key exists it will be used
User.timestamps!
puts User.create.cache_key  # User/:id-:updated_at (ie: User/4c7a940cbcd1b3319b000003-20100829170828)
