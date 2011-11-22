require 'test_helper'
require 'models'

class AssociationsTest < Test::Unit::TestCase
  should "allow changing class names" do
    class AwesomeUser
      include MongoMapper::Document

      many :posts, :class_name => 'AssociationsTest::AwesomePost', :foreign_key => :creator_id
    end
    AwesomeUser.collection.remove

    class AwesomeTag
      include MongoMapper::EmbeddedDocument

      key :name, String
      key :post_id, ObjectId

      belongs_to :post, :class_name => 'AssociationsTest::AwesomeUser'
    end

    class AwesomePost
      include MongoMapper::Document

      key :creator_id, ObjectId

      belongs_to :creator, :class_name => 'AssociationsTest::AwesomeUser'
      many :tags, :class_name => 'AssociationsTest::AwesomeTag', :foreign_key => :post_id
    end

    AwesomeUser.collection.remove
    AwesomePost.collection.remove

    user = AwesomeUser.create
    tag1 = AwesomeTag.new(:name => 'awesome')
    tag2 = AwesomeTag.new(:name => 'grand')
    post1 = AwesomePost.create(:creator => user, :tags => [tag1])
    post2 = AwesomePost.create(:creator => user, :tags => [tag2])

    user.reload
    user.posts.should == [post1, post2]

    post1 = post1.reload
    post1.tags.should == [tag1]
  end
  
  should "interoperate with aliased keys" do
    class AnotherUser
      include MongoMapper::Document

      many :goats, :class_name => 'AssociationsTest::AwesomeGoat', :foreign_key => :u_id
    end
    AnotherUser.collection.remove
    
    class AwesomeGoat
      include MongoMapper::Document
      
      key :name, String, :alias => :n
      key :user_id, ObjectId, :alias => :u_id
      
      belongs_to :user, :class_name => 'AssociationsTest::AnotherUser'
    end
    AwesomeGoat.collection.remove
    
    user = AnotherUser.create
    user.goats << goat1 = AwesomeGoat.new(:name => "g6")
    user.goats << goat2 = AwesomeGoat.new(:name => "g7")
    
    user.reload
    user.goats.should == [goat1, goat2]
    
    goat1.reload
    goat1.user.should == user
    
    goat2.reload
    goat2.user.should == user
  end
end