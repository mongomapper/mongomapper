$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'mongo_mapper'
require 'pp'

MongoMapper.database = 'testing'

class DowncasedString
  # to_mongo gets called anytime a value is assigned
  def self.to_mongo(value)
    value.nil? ? nil : value.to_s.downcase
  end

  # from mongo gets called anytime a value is read
  def self.from_mongo(value)
    value.nil? ? nil : value.to_s.downcase
  end
end

class User
  include MongoMapper::Document
  key :email, DowncasedString
end

pp User.create(:email => 'IDontLowerCaseThings@gmail.com')
