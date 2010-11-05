$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  key :email, String
end

# Drop collection and ensure unique index on email
User.collection.drop
User.ensure_index(:email, :unique => true)

User.create(:email => 'nunemaker@gmail.com')
User.create(:email => 'nunemaker@gmail.com')

puts "Count should only be one since the second create failed, count is: #{User.count}" # 1 because second was not created, but no exception raised
puts

# save method also takes options, including :safe
# which will force raise when duplicate is hit
begin
  user = User.new(:email => 'nunemaker@gmail.com')
  user.save(:safe => true)
rescue Mongo::OperationFailure => e
  puts 'Mongo Operation failure raised because duplicate email was entered'
  puts e.inspect
  puts
end

# Mark user model as safe, same as doing this...
# class User
#   include MongoMapper::Document
#   safe
# end
User.safe

begin
  User.create(:email => 'nunemaker@gmail.com')
rescue Mongo::OperationFailure => e
  puts 'Mongo Operation failure raised because duplicate email was entered'
  puts e.inspect
end
