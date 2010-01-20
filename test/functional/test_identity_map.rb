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
        set_collection_name 'people'
        plugin MongoMapper::Plugins::IdentityMap
        
        key :name, String
      end
      
      @post_class = Doc('Post') do
        set_collection_name 'posts'
        plugin MongoMapper::Plugins::IdentityMap
        
        key :title, String
        key :person_id, ObjectId
      end
      
      @post_class.belongs_to :person, :class => @person_class
      @person_class.many :posts, :class => @post_class
      
      @person_class.identity_map.clear
      @post_class.identity_map.clear
    end

    should "default identity map to hash" do
      Doc() do
        plugin MongoMapper::Plugins::IdentityMap
      end.identity_map.should == {}
    end

    should "share identity map with other classes" do
      map = @post_class.identity_map
      map.object_id.should == @person_class.identity_map.object_id
    end

    should "have identity map key that is always unique per document and class" do
      person = @person_class.new
      person.identity_map_key.should == "people:#{person.id}"
      @person_class.identity_map_key(person.id).should == person.identity_map_key

      post = @post_class.new
      post.identity_map_key.should == "posts:#{post.id}"
      @post_class.identity_map_key(post.id).should == post.identity_map_key

      person.identity_map_key.should_not == post.identity_map_key
    end

    should "add key to map when saved" do
      person = @person_class.new
      assert_not_in_map(person)
      person.save.should be_true
      assert_in_map(person)
    end
    
    should "allow saving with options" do
      person = @person_class.new
      assert_nothing_raised do
        person.save(:validate => false).should be_true
      end
    end

    should "remove key from map when deleted" do
      person = @person_class.create(:name => 'Fred')
      assert_in_map(person)
      person.destroy
      assert_not_in_map(person)
    end
    
    context "reload" do
      setup do
        @person = @person_class.create(:name => 'Fred')
      end

      should "remove object from identity and re-query" do
        assert_in_map(@person)
        Mongo::Collection.any_instance.expects(:find_one).once.returns({})
        @person.reload
      end
      
      should "add object back into map" do
        assert_in_map(@person)
        object_id = @person.object_id
        @person.reload.object_id.should == object_id
        assert_in_map(@person)
      end
    end

    context "#load" do
      setup do
        @id = Mongo::ObjectID.new
      end

      should "add document to map" do
        loaded = @person_class.load({'_id' => @id, 'name' => 'Frank'})
        assert_in_map(loaded)
      end

      should "return document if already in map" do
        first_load = @person_class.load({'_id' => @id, 'name' => 'Frank'})
        @person_class.identity_map.expects(:[]=).never
        second_load = @person_class.load({'_id' => @id, 'name' => 'Frank'})
        first_load.object_id.should == second_load.object_id
      end
    end
    
    context "#find (with one id)" do
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
    
    context "#find (with one id and options)" do
      setup do
        @person = @person_class.create(:name => 'Fred')
        @post1  = @person.posts.create(:title => 'I Love Mongo')
        @post2  = @person.posts.create(:title => 'Migrations Suck!')
      end

      # There are times when even though the id matches, other criteria doesn't
      # so we need to do the query to ensure that when criteria doesn't match
      # the document is in fact not found. 
      #
      # I'm open to not making this query if someone can figure out reliable
      # way to check if document matches criteria without querying.
      should "query the database" do
        assert_in_map(@post1)
        Mongo::Collection.any_instance.expects(:find_one)
        @person.posts.find(@post1.id)
      end
      
      should "return exact object" do
        assert_in_map(@post1)
        @person.posts.find(@post1.id)
        assert_in_map(@post1)
      end
    end
    
    context "#find (with multiple ids)" do
      should "add all documents to map" do
        person1 = @person_class.create(:name => 'Fred')
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')
        @person_class.identity_map.clear

        people = @person_class.find(person1.id, person2.id, person3.id)
        people.each { |person| assert_in_map(person) }
      end

      should "add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        @person_class.identity_map.clear
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')

        assert_not_in_map(person1)
        assert_in_map(person2)
        assert_in_map(person3)

        people = @person_class.find(person1.id, person2.id, person3.id)
        assert_in_map(people.first) # making sure one that wasn't mapped now is
        assert_in_map(person2)
        assert_in_map(person3)
      end
    end
    
    context "#first" do
      context "for object not in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
          @person_class.identity_map.clear
        end

        should "query the database" do
          Mongo::Collection.any_instance.expects(:find_one).once
          @person_class.first(:_id => @person.id)
        end

        should "add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
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
          @person_class.first(:_id => @person.id)
        end
        
        should "return exact object" do
          assert_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
          found_person.object_id.should == @person.object_id
        end
      end
    end
    
    context "#all" do
      should "add all documents to map" do
        person1 = @person_class.create(:name => 'Fred')
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')
        @person_class.identity_map.clear

        people = @person_class.all(:_id => [person1.id, person2.id, person3.id])
        people.each { |person| assert_in_map(person) }
      end

      should "add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        @person_class.identity_map.clear
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')

        assert_not_in_map(person1)
        assert_in_map(person2)
        assert_in_map(person3)

        people = @person_class.all(:_id => [person1.id, person2.id, person3.id])
        assert_in_map(people.first) # making sure one that wasn't mapped now is
        assert_in_map(person2)
        assert_in_map(person3)
      end
    end
    
    context "#find_by_id" do
      setup do
        @person = @person_class.create(:name => 'Bill')
      end
      
      should "return nil for document id not found in collection" do
        assert_in_map(@person)
        @person_class.find_by_id(1234).should be_nil
      end
    end
    
    context "single collection inheritance" do
      setup do
        class ::DocParent
          include MongoMapper::Document
          plugin MongoMapper::Plugins::IdentityMap
          
          key :_type, String
          key :name, String
          key :parent_id, ObjectId
          
          belongs_to :parent, :class_name => 'DocParent'
          one :child, :class_name => 'DocDaughter'
        end
        DocParent.collection.remove
        DocParent.identity_map.clear

        class ::DocDaughter < ::DocParent; end
      end

      teardown do
        Object.send :remove_const, 'DocParent'   if defined?(::DocParent)
        Object.send :remove_const, 'DocDaughter' if defined?(::DocDaughter)
      end

      should "share the same identity map 4eva" do
        @daughter = DocDaughter.create(:name => 'Jill')
        assert_in_map(@daughter)
        DocParent.identity_map_key(@daughter).should == DocDaughter.identity_map_key(@daughter)
        DocParent.identity_map.object_id.should == DocDaughter.identity_map.object_id
      end
      
      should "load from map when using parent collection inherited class" do
        @daughter = DocDaughter.create(:name => 'Jill')
        DocParent.find(@daughter.id).object_id.should == @daughter.object_id
      end
      
      should "work correctly with belongs to proxy" do
        @parent = DocParent.create(:name => 'Dad')
        assert_in_map(@parent)
        
        @daughter = DocDaughter.create(:name => 'Jill', :parent => @parent)
        assert_in_map(@daughter)
        @parent.object_id.should == @daughter.parent.object_id
      end
      
      should "work correctly with one proxy" do
        @daughter = DocDaughter.create(:name => 'Jill')
        assert_in_map(@daughter)

        @parent = DocParent.create(:name => 'Dad', :child => @daughter)
        assert_in_map(@parent)
        
        @parent.child.object_id.should == @daughter.object_id
      end
    end
  end
end