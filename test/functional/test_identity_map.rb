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
      @person_class = Doc('Person') { key :name, String }
      @person_class.identity_map = {}
      
      @post_class = Doc('Post') { key :title, String }
      @post_class.identity_map = {}
    end

    should "default identity map to hash" do
      map = Doc().identity_map
      map.should == {}
    end

    should "share identity map with other classes" do
      map = @post_class.identity_map
      map.object_id.should == @person_class.identity_map.object_id
    end

    should "have identity map key that is always unique per document and class" do
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
      person = @person_class.create(:name => 'Fred')

      assert_in_map(person)
      person.destroy
      assert_not_in_map(person)
    end
    
    context "find with one id" do
      context "for object not in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
          @person_class.identity_map.clear
        end

        should "query the database" do
          Mongo::Collection.any_instance.expects(:find_one).once
          @person_class.find(@person.id)
        end

        should "add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.find(@person.id)
          assert_in_map(found_person)
        end
      end

      context "for object in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
        end

        should "not query database" do
          Mongo::Collection.any_instance.expects(:find).never
          Mongo::Collection.any_instance.expects(:find_one).never
          @person_class.find(@person.id)
        end
        
        should "return exact object" do
          assert_in_map(@person)
          found_person = @person_class.find(@person.id)
          found_person.object_id.should == @person.object_id
        end
      end
    end
  end
end