$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class User
  include MongoMapper::Document
  
  key :name, String
  key :tags, Array
end
User.collection.remove # empties collection

User.create(:name => 'John',  :tags => %w[ruby mongo], :age => 28)
User.create(:name => 'Bill',  :tags => %w[ruby mongo], :age => 30)
User.create(:name => 'Frank', :tags => %w[mongo],      :age => 35)
User.create(:name => 'Steve', :tags => %w[html5 css3], :age => 27)

[

  User.all(:name => 'John'),
  User.all(:tags => %w[mongo]),
  User.all(:tags.all => %w[ruby mongo]),
  User.all(:age.gte => 30),

  User.where(:age.gt => 27).sort(:age).all,
  User.where(:age.gt => 27).sort(:age.desc).all,
  User.where(:age.gt => 27).sort(:age).limit(1).all,
  User.where(:age.gt => 27).sort(:age).skip(1).limit(1).all,

].each do |result|
  pp result
  puts
end