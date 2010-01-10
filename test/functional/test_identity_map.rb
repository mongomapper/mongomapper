require 'test_helper'

class IdentityMapTest < Test::Unit::TestCase
  def assert_in_map(resource)
    resource.identity_map.keys.should include(resource.identity_map_key)
    mapped_resource = resource.identity_map[resource.identity_map_key]
    resource.object_id.should == mapped_resource.object_id
  end
  
  def assert_not_in_map(resource)
    resource.identity_map.keys.should_not include(resource.identity_map_key)
  end
  
  context "Document" do
    setup do
      @person_class = Doc('Person') do
        key :name, String
      end
      
      @post_class = Doc('Post') do
        key :title, String
      end
    end

    should "have an identity map method" do
      map = @person_class.identity_map
      map.should be_instance_of(Moneta::Memory)
    end
    
    should "share identity map with other classes" do
      map = @post_class.identity_map
      map.object_id.should == @person_class.identity_map.object_id
    end
    
    should "have identity map key that is always unique" do
      person = @person_class.new
      person.identity_map_key.should == "Person:#{person.id}"
      
      post = @post_class.new
      post.identity_map_key.should == "Post:#{post.id}"
      
      person.identity_map_key.should_not == post.identity_map_key
    end
    
    should "add key to map when saved" do
      person = @person_class.new
      assert_not_in_map(person)
      person.save.should be_true
      
      mapped_person = person.identity_map[person.identity_map_key]
      person.object_id.should == mapped_person.object_id
    end
    
    should "remove key from map when deleted" do
      person = @person_class.create
      
      assert_in_map(person)
      person.destroy
      assert_not_in_map(person)
    end
    
    should "load object from identity map if exists" do
      person = @person_class.create
      assert_in_map(person)
      
      Mongo::Collection.any_instance.expects(:find).never
      Mongo::Collection.any_instance.expects(:find_one).never
      
      found_person = @person_class.find(person.id)
      found_person.object_id.should == person.object_id
    end
  end
end