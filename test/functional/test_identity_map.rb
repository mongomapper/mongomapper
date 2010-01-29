require 'test_helper'

class IdentityMapTest < Test::Unit::TestCase
  def assert_in_map(*resources)
    [resources].flatten.each do |resource|
      resource.identity_map.keys.should include(resource._id)
      mapped_resource = resource.identity_map[resource._id]
      resource.should equal(mapped_resource)
    end
  end

  def assert_not_in_map(*resources)
    [resources].flatten.each do |resource|
      resource.identity_map.keys.should_not include(resource._id)
    end
  end

  def expect_no_queries
    Mongo::Collection.any_instance.expects(:find_one).never
    Mongo::Collection.any_instance.expects(:find).never
  end

  def expects_one_query
    Mongo::Collection.any_instance.expects(:find_one).once.returns({})
  end

  context "Document" do
    setup do
      MongoMapper::Plugins::IdentityMap.models.clear

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

      @post_class.identity_map_on
      @person_class.identity_map_on
      MongoMapper::Plugins::IdentityMap.clear
    end

    should "track identity mapped models" do
      MongoMapper::Plugins::IdentityMap.models.should == [@person_class, @post_class].to_set
    end

    should "be able to clear the map of all models" do
      person = @person_class.create(:name => 'John')
      post = @post_class.create(:title => 'IM 4eva')
      assert_in_map(person, post)

      MongoMapper::Plugins::IdentityMap.clear

      assert_not_in_map(person, post)

      [@person_class, @post_class].each { |klass| klass.identity_map.should == {} }
    end
    
    context "IM on off status" do
      teardown do
        @post_class.identity_map_on
        @person_class.identity_map_on
      end

      should "default identity map status to on" do
        Doc { plugin MongoMapper::Plugins::IdentityMap }.identity_map_status.should be_true
      end

      should "be true if on" do
        @post_class.identity_map_on
        @post_class.should be_identity_map_on
        @post_class.should_not be_identity_map_off
      end

      should "be false if off" do
        @post_class.identity_map_off
        @post_class.should be_identity_map_off
        @post_class.should_not be_identity_map_on
      end

      should "not share with other classes" do
        @post_class.identity_map_off
        @person_class.identity_map_on
        @post_class.identity_map_status.should_not == @person_class.identity_map_status
      end
    end

    should "default identity map to hash" do
      Doc { plugin MongoMapper::Plugins::IdentityMap }.identity_map.should == {}
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
        expects_one_query
        @person.reload
      end
      
      should "add object back into map" do
        assert_in_map(@person)
        before_reload = @person
        @person.reload.should equal(before_reload)
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
        first_load.should equal(second_load)
      end
    end

    context "#find (with one id)" do
      context "for object not in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
          @person_class.identity_map.clear
        end

        should "query the database" do
          expects_one_query
          @person_class.find(@person.id)
        end

        should "add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.find(@person.id)
          assert_in_map(found_person)
        end

        should "return nil if not found " do
          @person_class.find(1234).should be_nil
        end
      end

      context "for object in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
        end

        should "not query database" do
          expect_no_queries
          @person_class.find(@person.id)
        end

        should "return exact object" do
          assert_in_map(@person)
          found_person = @person_class.find(@person.id)
          found_person.should equal(@person)
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
        expects_one_query
        @person.posts.find(@post1.id)
      end
      
      should "return exact object" do
        assert_in_map(@post1)
        @person.posts.find(@post1.id)
        assert_in_map(@post1)
      end
      
      should "return nil if not found " do
        @person.posts.find(1234).should be_nil
      end
    end

    context "#find (with multiple ids)" do
      should "add all documents to map" do
        person1 = @person_class.create(:name => 'Fred')
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')
        @person_class.identity_map.clear

        people = @person_class.find(person1.id, person2.id, person3.id)
        assert_in_map(people)
      end

      should "add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        @person_class.identity_map.clear
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')

        assert_not_in_map(person1)
        assert_in_map(person2, person3)

        people = @person_class.find(person1.id, person2.id, person3.id)
        assert_in_map(people.first) # making sure one that wasn't mapped now is
        assert_in_map(person2, person3)
      end
    end

    context "#first" do
      context "for object not in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
          @person_class.identity_map.clear
        end

        should "query the database" do
          expects_one_query
          @person_class.first(:_id => @person.id)
        end

        should "add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
          assert_in_map(found_person)
        end
        
        should "return nil if not found" do
          @person_class.first(:name => 'Bill').should be_nil
        end
      end

      context "for object in map" do
        setup do
          @person = @person_class.create(:name => 'Fred')
        end

        should "not query database" do
          expect_no_queries
          @person_class.first(:_id => @person.id)
        end

        should "return exact object" do
          assert_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
          found_person.should equal(@person)
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
        assert_in_map(people)
      end

      should "add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        @person_class.identity_map.clear
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')

        assert_not_in_map(person1)
        assert_in_map(person2, person3)

        people = @person_class.all(:_id => [person1.id, person2.id, person3.id])
        # people.first is making sure one that wasn't mapped now is
        assert_in_map(people.first, person2, person3)
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

    context "querying and selecting certain fields" do
      setup do
        @person = @person_class.create(:name => 'Bill')
        @person_class.identity_map.clear
      end

      should "not add to map" do
        assert_not_in_map(@person)
        @person_class.first(:_id => @person.id, :select => 'name').should == @person
        @person_class.first(:_id => @person.id, 'fields' => ['name']).should == @person
        @person_class.last(:_id => @person.id, :select => 'name', :order => 'name').should == @person
        @person_class.find(@person.id, :select => 'name').should == @person
        @person_class.all(:_id => @person.id, :select => 'name').should == [@person]
        assert_not_in_map(@person)
      end
      
      should "return nil if not found" do
        @person_class.find(1234, :select => 'name').should be_nil
      end
    end

    context "single collection inherited models" do
      setup do
        class ::Item
          include MongoMapper::Document
          plugin MongoMapper::Plugins::IdentityMap
          
          key :_type, String
          key :title, String
          key :parent_id, ObjectId
          
          belongs_to :parent, :class_name => 'Item'
          one :blog, :class_name => 'Blog', :foreign_key => 'parent_id'
        end
        Item.collection.remove

        class ::Blog < ::Item; end

        class ::BlogPost < ::Item
          key :blog_id, ObjectId
          belongs_to :blog
        end
      end

      teardown do
        Object.send :remove_const, 'Item'   if defined?(::Item)
        Object.send :remove_const, 'Blog' if defined?(::Blog)
        Object.send :remove_const, 'BlogPost' if defined?(::BlogPost)
      end

      should "share the same identity map" do
        blog = Blog.create(:title => 'Jill')
        assert_in_map(blog)
        Item.identity_map.should equal(Blog.identity_map)
      end
      
      should "not query when finding by _id and _type" do
        blog = Blog.create(:title => 'Blog')
        post = BlogPost.create(:title => 'Mongo Rocks', :blog => blog)
        Item.identity_map.clear
        
        blog = Item.find(blog.id)
        post = Item.find(post.id)
        assert_in_map(blog, post)
        
        expect_no_queries
        post.blog
        Blog.find(blog.id)
      end
      
      should "load from map when using parent collection inherited class" do
        blog = Blog.create(:title => 'Jill')
        Item.find(blog.id).should equal(blog)
      end
      
      should "work correctly with belongs to proxy" do
        root = Item.create(:title => 'Root')
        assert_in_map(root)
        
        blog = Blog.create(:title => 'Jill', :parent => root)
        assert_in_map(blog)
        root.should equal(blog.parent)
      end
      
      should "work correctly with one proxy" do
        blog = Blog.create(:title => 'Jill')
        assert_in_map(blog)

        root = Item.create(:title => 'Root', :blog => blog)
        assert_in_map(root)
        root.blog.should equal(blog)
      end
      
      should "work correctly with one proxy create" do
        root = Item.create(:title => 'Root')
        blog = root.blog.create(:title => 'Blog')
        blog.parent.should equal(root)
      end
    end

    context "without identity map" do
      should "not add to map on save" do
        @post_class.without_identity_map do
          post = @post_class.create(:title => 'Bill')
          assert_not_in_map(post)
        end
      end
      
      should "not remove from map on delete" do
        post = @post_class.create(:title => 'Bill')
        assert_in_map(post)
        
        @post_class.without_identity_map do
          post.destroy
        end
        
        assert_in_map(post)
      end
      
      should "not add to map when loading" do
        @post_class.without_identity_map do
          post = @post_class.load({'_id' => Mongo::ObjectID.new, 'title' => 'Awesome!'})
          assert_not_in_map(post)
        end
      end
      
      should "not load from map when loading" do
        post = @post_class.create(:title => 'Awesome!')
        
        @post_class.without_identity_map do
          loaded = @post_class.load('_id' => post._id, 'title' => 'Awesome!')
          loaded.should_not equal(post)
        end
      end
      
      context "all" do
        should "not add to map" do
          @post_class.without_identity_map do
            post1 = @post_class.create(:title => 'Foo')
            post2 = @post_class.create(:title => 'Bar')
            @post_class.identity_map.clear
            
            assert_not_in_map(@post_class.all)
          end
        end
      end
      
      context "first" do
        should "not add to map" do
          @post_class.without_identity_map do
            post1 = @post_class.create(:title => 'Foo')
            post2 = @post_class.create(:title => 'Bar')
            @post_class.identity_map.clear
            
            assert_not_in_map(@post_class.first)
          end
        end
      end
      
      context "last" do
        should "not add to map" do
          @post_class.without_identity_map do
            post1 = @post_class.create(:title => 'Foo')
            post2 = @post_class.create(:title => 'Bar')
            @post_class.identity_map.clear
            
            assert_not_in_map(@post_class.last(:order => 'title'))
          end
        end
      end
    end
  end
end