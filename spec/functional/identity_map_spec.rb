require 'spec_helper'

describe "IdentityMap" do
  def assert_in_map(*resources)
    [resources].flatten.each do |resource|
      MongoMapper::Plugins::IdentityMap.include?(resource).should be_truthy
    end
  end

  def assert_not_in_map(*resources)
    [resources].flatten.each do |resource|
      MongoMapper::Plugins::IdentityMap.include?(resource).should be_falsey
    end
  end

  def expect_no_queries
    expect_any_instance_of(Mongo::Collection).to receive(:find_one).never
    expect_any_instance_of(Mongo::Collection).to receive(:find).never
  end

  def expects_one_query
    expect_any_instance_of(Mongo::Collection).to receive(:find_one).once.and_return({})
  end

  def clear_identity_map
    MongoMapper::Plugins::IdentityMap.clear
  end

  it "should default identity map to off" do
    MongoMapper::Plugins::IdentityMap.enabled?.should be_falsey
  end

  context "Document" do
    before do
      @original_identity_map_enabled = MongoMapper::Plugins::IdentityMap.enabled
      MongoMapper::Plugins::IdentityMap.enabled = true

      @person_class = Doc('Person') do
        key :name, String
      end

      @post_class = Doc('Post') do
        key :title, String
        key :person_id, ObjectId
      end

      @post_class.belongs_to :person, :class => @person_class
      @person_class.many :posts, :class => @post_class

      clear_identity_map
    end

    after do
      MongoMapper::Plugins::IdentityMap.enabled = @original_identity_map_enabled
    end

    it "should be able to clear the map of all models" do
      person = @person_class.create(:name => 'John')
      post = @post_class.create(:title => 'IM 4eva')

      assert_in_map(person, post)
      clear_identity_map
      assert_not_in_map(person, post)

      MongoMapper::Plugins::IdentityMap.repository.should be_empty
    end

    context ".use" do
      before do
        @person = @person_class.create
        clear_identity_map
      end

      it "should use the identity map" do
        MongoMapper::Plugins::IdentityMap.enabled = false
        MongoMapper::Plugins::IdentityMap.use do
          @person_class.find(@person.id).should equal(@person_class.find(@person.id))
        end
      end

      it "should clear the map" do
        MongoMapper::Plugins::IdentityMap.enabled = false
        MongoMapper::Plugins::IdentityMap.repository['hello'] = 'world'
        MongoMapper::Plugins::IdentityMap.use do
          @person_class.find(@person.id)
        end
        MongoMapper::Plugins::IdentityMap.repository.empty?.should be_truthy
      end

      it "should set enabled back to original status" do
        MongoMapper::Plugins::IdentityMap.enabled = false
        MongoMapper::Plugins::IdentityMap.enabled?.should be_falsey
        MongoMapper::Plugins::IdentityMap.use do
          MongoMapper::Plugins::IdentityMap.enabled?.should be_truthy
        end
        MongoMapper::Plugins::IdentityMap.enabled?.should be_falsey
      end
    end

    context ".without" do
      before do
        @person = @person_class.create
        clear_identity_map
      end

      it "should skip the map" do
        MongoMapper::Plugins::IdentityMap.without do
          @person_class.find(@person.id).should_not equal(@person_class.find(@person.id))
        end
      end

      it "should set enabled back to original value" do
        MongoMapper::Plugins::IdentityMap.enabled = true
        MongoMapper::Plugins::IdentityMap.enabled?.should be_truthy
        MongoMapper::Plugins::IdentityMap.without do
          MongoMapper::Plugins::IdentityMap.enabled?.should be_falsey
        end
        MongoMapper::Plugins::IdentityMap.enabled?.should be_truthy
      end
    end

    it "should default identity map to hash" do
      MongoMapper::Plugins::IdentityMap.repository.should == {}
    end

    it "should add key to map when saved" do
      person = @person_class.new
      assert_not_in_map(person)
      person.save.should be_truthy
      assert_in_map(person)
    end

    it "should allow saving with options" do
      person = @person_class.new
      assert_not_in_map(person)
      person.save(:validate => false).should be_truthy
      assert_in_map(person)
    end

    it "should remove key from map when deleted" do
      person = @person_class.create(:name => 'Fred')
      assert_in_map(person)
      person.delete
      assert_not_in_map(person)
    end

    it "should remove key from map when destroyed" do
      person = @person_class.create(:name => 'Fred')
      assert_in_map(person)
      person.destroy
      assert_not_in_map(person)
    end

    context "#reload" do
      before do
        @person = @person_class.create(:name => 'Fred')
      end

      it "should re-query the object" do
        assert_in_map(@person)
        expects_one_query
        @person.reload
      end
    end

    context "#load" do
      before do
        @id = BSON::ObjectId.new
      end

      it "should add document to map" do
        loaded = @person_class.load('_id' => @id, 'name' => 'Frank')
        assert_in_map(loaded)
      end

      it "should return document if already in map" do
        first_load = @person_class.load('_id' => @id, 'name' => 'Frank')
        second_load = @person_class.load('_id' => @id, 'name' => 'Frank')
        first_load.should equal(second_load)
      end
    end

    context "#find (with one id)" do
      it "should return nil if not found " do
        @person_class.find(1234).should be_nil
      end

      context "for object not in map" do
        before do
          @person = @person_class.create(:name => 'Fred')
          clear_identity_map
        end

        it "should query the database" do
          expects_one_query
          @person_class.find(@person.id)
        end

        it "should add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.find(@person.id)
          assert_in_map(found_person)
        end
      end

      context "for object in map" do
        before do
          @person = @person_class.create(:name => 'Fred')
        end

        it "should not query database" do
          expect_no_queries
          @person_class.find(@person.id)
        end

        it "should return exact object" do
          assert_in_map(@person)
          found_person = @person_class.find(@person.id)
          found_person.should equal(@person)
        end
      end
    end

    context "#find (with one id and options)" do
      before do
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
      it "should query the database" do
        assert_in_map(@post1)
        expects_one_query
        @person.posts.find(@post1.id)
      end

      it "should return exact object" do
        assert_in_map(@post1)
        post = @person.posts.find(@post1.id)
        post.should equal(@post1)
      end

      it "should return nil if not found " do
        @person.posts.find(1234).should be_nil
      end
    end

    context "#find (with multiple ids)" do
      it "should add all documents to map" do
        person1 = @person_class.create(:name => 'Fred')
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')
        clear_identity_map

        people = @person_class.find(person1.id, person2.id, person3.id)
        assert_in_map(people)
      end

      it "should add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        clear_identity_map
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
        before do
          @person = @person_class.create(:name => 'Fred')
          clear_identity_map
        end

        it "should query the database" do
          expects_one_query
          @person_class.first(:_id => @person.id)
        end

        it "should add object to map" do
          assert_not_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
          assert_in_map(found_person)
        end

        it "should return nil if not found" do
          @person_class.first(:name => 'Bill').should be_nil
        end
      end

      context "for object in map" do
        before do
          @person = @person_class.create(:name => 'Fred')
        end

        it "should not query database" do
          expect_no_queries
          @person_class.first(:_id => @person.id)
        end

        it "should return exact object" do
          assert_in_map(@person)
          found_person = @person_class.first(:_id => @person.id)
          found_person.should equal(@person)
        end
      end
    end

    context "#all" do
      it "should add all documents to map" do
        person1 = @person_class.create(:name => 'Fred')
        person2 = @person_class.create(:name => 'Bill')
        person3 = @person_class.create(:name => 'Jesse')
        clear_identity_map

        people = @person_class.all(:_id => [person1.id, person2.id, person3.id])
        assert_in_map(people)
      end

      it "should add missing documents to map and return existing ones" do
        person1 = @person_class.create(:name => 'Fred')
        clear_identity_map
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
      before do
        @person = @person_class.create(:name => 'Bill')
      end

      it "should return nil for document id not found in collection" do
        assert_in_map(@person)
        @person_class.find_by_id(BSON::ObjectId.new).should be_nil
      end
    end

    context "#remove_documents_from_map" do
      before do
        @person = @person_class.create(:name => 'Fred')
      end

      it "should remove documents from the map" do
        assert_in_map @person
        @person_class.remove_documents_from_map(@person)
        assert_not_in_map @person
      end
    end

    context "querying and selecting certain fields" do
      before do
        @person = @person_class.create(:name => 'Bill')
        clear_identity_map
      end

      it "should not add to map" do
        assert_not_in_map(@person)
        @person_class.first(:_id => @person.id, :select => 'name').should == @person
        @person_class.first(:_id => @person.id, 'fields' => ['name']).should == @person
        @person_class.last(:_id => @person.id, :select => 'name', :order => 'name').should == @person
        @person_class.fields(:name).find(@person.id).should == @person
        @person_class.all(:_id => @person.id, :select => 'name').should == [@person]
        assert_not_in_map(@person)
      end

      it "should not add to map using where and each" do
        @person_class.where(:id => @person.id).each{|_|}
        assert_in_map(@person)
        @person_class.where(:id => @person.id).only(:id).each{|_|}
        assert_not_in_map(@person)
      end

      it "should return nil if not found" do
        @person_class.fields(:name).find(BSON::ObjectId.new).should be_nil
      end
    end

    context "single collection inherited models" do
      before do
        class ::Item
          include MongoMapper::Document

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

      after do
        Object.send :remove_const, 'Item' if defined?(::Item)
        Object.send :remove_const, 'Blog' if defined?(::Blog)
        Object.send :remove_const, 'BlogPost' if defined?(::BlogPost)
      end

      it "should not query when finding by _id and _type" do
        blog = Blog.create(:title => 'Blog')
        post = BlogPost.create(:title => 'Mongo Rocks', :blog => blog)
        clear_identity_map

        blog = Item.find(blog.id)
        post = Item.find(post.id)
        assert_in_map(blog, post)

        expect_no_queries
        post.blog
        Blog.find(blog.id)
      end

      it "should load from map when using parent collection inherited class" do
        blog = Blog.create(:title => 'Jill')
        Item.find(blog.id).should equal(blog)
      end

      it "should work correctly with belongs to proxy" do
        root = Item.create(:title => 'Root')
        assert_in_map(root)

        blog = Blog.create(:title => 'Jill', :parent => root)
        assert_in_map(blog)
        root.should equal(blog.parent.target)
      end

      it "should work correctly with one proxy" do
        blog = Blog.create(:title => 'Jill')
        assert_in_map(blog)

        root = Item.create(:title => 'Root', :blog => blog)
        assert_in_map(root)
        blog.should equal(root.blog.target)
      end

      it "should work correctly with one proxy create" do
        root = Item.create(:title => 'Root')
        blog = root.create_blog(:title => 'Blog')
        blog.parent.should equal(root)
      end
    end
  end
end
