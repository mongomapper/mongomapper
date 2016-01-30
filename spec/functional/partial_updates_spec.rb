require 'spec_helper'

describe "Partial Updates" do
  before do
    @klass = Doc("PartialUpdates") do
      key :string_field, String
      key :array_field, Array
      key :hash_field, Hash
      key :integer_field, Integer

      timestamps!
    end

    @dealiased_keys_class = Doc("DealiasedKeys") do
      key :foo, :abbr => "f"
    end

    @pet_klass = EDoc('Pet') do
      key :name, String
      key :flag, Boolean
    end

    @person_class = Doc('Person') do
      key :name, String
    end
    @person_class.many :pets, :class => @pet_klass

    @author_class = Doc("Author")

    @post_class = Doc("Post") do
      key :title, String
    end
    @post_class.one :author, :as => :authorable, :class => @author_class, :dependent => :nullify

    @comments_class = Doc("Comment") do
      key :text, String
      key :owner_id, ObjectId
    end

    @klass.partial_updates = true
    @dealiased_keys_class.partial_updates = true
    @person_class.partial_updates = true
    @post_class.partial_updates = true
    @author_class.partial_updates = true
    @comments_class.partial_updates = true

    @obj = @klass.new
  end

  after do
    @klass.destroy_all
    @dealiased_keys_class.destroy_all
    @person_class.destroy_all
    @author_class.destroy_all
    @post_class.destroy_all
    @comments_class.destroy_all
  end

  it "should be able to turn on and off partial updates for the klass" do
    @klass.partial_updates = false
    @klass.partial_updates.should be_falsey

    @klass.partial_updates = true
    @klass.partial_updates.should be_truthy
  end

  it "should have partial updates off by default" do
    Doc {}.partial_updates.should be_falsey
  end

  it "should update fields" do
    @obj.string_field = "foo"
    @obj.string_field.should == "foo"
    @obj.save!

    @obj.string_field = "bar"
    @obj.string_field.should == "bar"
    @obj.save!
  end

  describe "with partial updates on" do
    it "should only update fields that have changed on save" do
      @obj.string_field = "foo"
      @obj.save!

      mock_collection = double 'collection'
      allow(@obj).to receive(:collection).and_return mock_collection

      expect(@obj.collection).to receive(:update).with({:_id => @obj.id}, {
        '$set' => {
          "string_field" => "bar",
          "updated_at" => kind_of(Time),
        }
      }, {})

      @obj.string_field = "bar"
      @obj.save!
    end

    it "should properly nullify associations" do
      @post = @post_class.create
      @author = @author_class.new
      @post.author = @author
      @author.reload
      @author.authorable_id.should == @post.id

      @post.author = @author_class.new

      @author.reload
      @author.authorable_id.should be_nil
    end
  end

  describe "when partial updates are off" do
    before do
      @klass.partial_updates = false
      @obj = @klass.new

      @post_class.partial_updates = false
      @author_class.partial_updates = false
    end

    it "should update all attributes" do
      @obj.string_field = "foo"
      @obj.save!

      mock_collection = double 'collection'
      allow(@obj).to receive(:collection).and_return mock_collection

      expect(@obj.collection).to receive(:save).with({
        "_id" => @obj.id,
        "string_field" => "bar",
        "array_field" => [],
        "hash_field" => {},
        "created_at" => kind_of(Time),
        "updated_at" => kind_of(Time),
      }, {})

      @obj.string_field = "bar"
      @obj.save!
    end

    it "should raise if fields_for_partial_update is called" do
      lambda {
        @obj.fields_for_partial_update
      }.should raise_error(MongoMapper::Plugins::PartialUpdates::PartialUpdatesDisabledError)
    end

    it "should properly nullify associations" do
      @post = @post_class.create
      @author = @author_class.new
      @post.author = @author
      @author.reload
      @author.authorable_id.should == @post.id

      @post.author = @author_class.new

      @author.reload
      @author.authorable_id.should be_nil
    end
  end

  describe "detecting attribute changes" do
    it "should be able to find the fields_for_partial_update" do
      @obj.string_field = "foo"

      fields_for_partial_updates = @obj.fields_for_partial_update
      fields_for_partial_updates.keys.should =~ [:set_fields, :unset_fields]
      fields_for_partial_updates[:set_fields].should =~ ["_id", "string_field"]
      fields_for_partial_updates[:unset_fields] == []
    end

    it "should not find any if no fields have changed" do
      @obj.save!
      @obj.fields_for_partial_update.should == {
        :set_fields => [],
        :unset_fields => []
      }
    end

    it "should be cleared after save" do
      @obj.string_field = "foo"
      @obj.fields_for_partial_update[:set_fields].should =~ ["_id", "string_field"]

      @obj.save!

      @obj.fields_for_partial_update.should == {
        :set_fields => [],
        :unset_fields => []
      }
    end

    it "should detect in place updates with a string" do
      @obj.string_field = "foo"
      @obj.save!

      @obj.string_field.gsub!(/foo/, "bar")
      @obj.string_field.should == "bar"
      @obj.fields_for_partial_update[:set_fields].should == ["string_field"]
    end

    it "should detect in place updates with an array" do
      @obj.array_field = [1]
      @obj.save!

      @obj.array_field << 2
      @obj.array_field.should == [1,2]
      @obj.fields_for_partial_update[:set_fields].should == ["array_field"]
    end

    it "should detect non-key based values" do
      @obj.attributes = { :non_keyed_field => "foo" }
      @obj.fields_for_partial_update[:set_fields].should =~ ["_id", "non_keyed_field"]
    end

    it "should allow fields that have numbers to be changed" do
      @obj.integer_field = 1
      @obj.save!

      @obj.integer_field = 2
      @obj.fields_for_partial_update[:set_fields].should == ["integer_field"]
    end

    it "should update fields with dealiased keys" do
      @obj = @dealiased_keys_class.new(:foo => "one")
      @obj.fields_for_partial_update[:set_fields].should =~ ["_id", "f"]
    end

    it "should update fields that have been deleted" do
      @obj.attributes = { :foo => "bar" }
      @obj.save!

      attrs = @obj.attributes.dup
      attrs.delete("foo")

      allow(@obj).to receive(:attributes).and_return(attrs)

      @obj.fields_for_partial_update.should == {
        :set_fields => [],
        :unset_fields => ["foo"]
      }
    end

    it "should have an empty list of fields_for_partial_update[:set_fields] after reload" do
      @obj.integer_field = 10
      @obj.save!

      @obj.reload
      @obj.fields_for_partial_update.should == {
        :set_fields => [],
        :unset_fields => []
      }
    end

    it "should return [] when re-found with find()" do
      @obj.save!
      obj_refound = @klass.find(@obj.id)
      obj_refound.fields_for_partial_update.should == {
        :set_fields => [],
        :unset_fields => []
      }
    end

    it "should return a field when re-found with find() and changed" do
      @obj.save!
      obj_refound = @klass.find(@obj.id)
      obj_refound.string_field = "foo"
      obj_refound.fields_for_partial_update[:set_fields].should == ["string_field"]
    end

    it "should return a field when it is a new object and it's been initialized with new" do
      @obj = @klass.new({
        :string_field => "foo"
      })
      @obj.fields_for_partial_update[:set_fields].should =~ ["_id", "string_field"]
    end

    it "should be able to detect any change in an array (deep copy)" do |variable|
      @obj = @klass.create!({ :array_field => [["array", "of"], ["arrays"]] })
      @obj.array_field.last.unshift "many"
      @obj.save!
      @obj.reload
      @obj.array_field.last.should == ["many", "arrays"]
    end

    it "should be able to detect any change in an array (super deep copy)" do |variable|
      @obj = @klass.create!({ :array_field => [["array", "of"], ["arrays"]] })
      @obj.array_field.last << "foo"
      @obj.fields_for_partial_update[:set_fields].should == ["array_field"]
    end

    it "should be able to detect a deep change in a hash" do
      @obj = @klass.new({
        :hash_field => {
          :a => {
            :really => {
              :deep => :hash
            }
          }
        }
      })
      @obj.save!

      @obj.fields_for_partial_update[:set_fields].should == []

      @obj.hash_field[:a][:really] = {
        :really => {
          :really => {
            :really => {
              :deep => :hash
            }
          }
        }
      }

      @obj.fields_for_partial_update[:set_fields].should == ["hash_field"]
    end
  end

  it "should set timestamps" do
    @obj.string_field = "foo"
    @obj.save!

    @obj.created_at.should_not be_nil
    @obj.updated_at.should_not be_nil

    @obj.reload
    @obj.created_at.should_not be_nil
    @obj.updated_at.should_not be_nil
  end

  it "should be able to reload set values" do
    @obj.string_field = "foo"
    @obj.integer_field = 1
    @obj.save!

    @obj.reload
    @obj.string_field.should == "foo"
    @obj.integer_field.should == 1
  end

  it "should be able to reload documents created from create" do
    @obj = @klass.create({
      :string_field => "foo",
      :integer_field => 1
    })

    @obj.reload
    @obj.string_field.should == "foo"
    @obj.integer_field.should == 1
  end

  describe "with embedded documents" do
    before do
      @person = @person_class.new
      @person.pets.build
      @person.save!
      @person.reload
      @pet = @person.pets.first
    end

    it "should have the child as an update key when the child changes" do
      @pet.name = "monkey"
      @person.fields_for_partial_update[:set_fields].should == ["pets"]
    end
  end

  describe "with a has many" do
    before do
      @post_class.partial_updates = true
      @comments_class.partial_updates = true

      @post_class.many :comments, :class => @comments_class, :foreign_key => :owner_id
    end

    after do
      @post_class.destroy_all
      @comments_class.destroy_all
    end

    it "should save the children assigned through a hash in new (when assigned through new)" do
      @post = @post_class.new({
        :title => "foobar",
        "comments" => [
          { "text" => "one" }
        ],
      })

      @post.save!
      @post.reload

      @post.title.should == "foobar"
      @post.comments.length == 1
      @post.comments.first.text.should == 'one'
    end

    it "should save the children assigned through a hash in new (when assigned through new) even when the children are refernced before save" do
      @post = @post_class.new({
        :title => "foobar",
        "comments" => [
          { "text" => "one" }
        ],
      })

      # this line is important - it causes the proxy to load
      @post.comments.length == 1

      @post.comments.first.should be_persisted
      @post.comments.first.fields_for_partial_update[:set_fields].should == []

      @post.save!
      @post.reload

      @post.title.should == "foobar"
      @post.comments.length.should == 1
      @post.comments.first.text.should == 'one'
    end

    it "should update the children after a save if fields have changed" do
      @post = @post_class.new({
        :title => "foobar",
        "comments" => [
          { "text" => "one" }
        ],
      })

      @post.comments.length == 1

      @post.save!
      @post.reload

      comment = @post.comments.first
      comment.text = "two"
      comment.save!
      comment.reload
      comment.text.should == "two"
    end

    it "should save the built document when saving parent" do
      post = @post_class.create(:title => "foobar")
      comment = post.comments.build(:text => 'Foo')

      post.save!

      post.should_not be_new
      comment.should_not be_new
    end

    it "should clear objects between test runs" do
      @post_class.count.should == 0
      @comments_class.count.should == 0
    end

    it "should only save one object with create" do
      @post_class.count.should == 0
      @comments_class.count.should == 0

      @post_class.create(:title => "foobar")
      @comments_class.create()

      @post_class.count.should == 1
      @comments_class.count.should == 1
    end

    it "should save an association with create with the correct attributes" do
      post = @post_class.create(:title => "foobar")
      @comments_class.create("text" => 'foo')

      @comments_class.count.should == 1
      @comments_class.first.text.should == "foo"
    end

    it "should be able to find objects through the association proxy" do
      post = @post_class.create!(:title => "foobar")
      comment = @comments_class.create!("text" => 'foo')

      @comments_class.count.should == 1
      @comments_class.first.text.should == "foo"

      post.comments << comment

      post.comments.count.should == 1
      post.comments.first.text.should == "foo"
      post.comments.all("text" => "foo").length.should == 1
    end

    it "should work with destroy all and conditions" do
      @post_class.partial_updates = true
      @comments_class.partial_updates = true

      post = @post_class.create(:title => "foobar")
      post.comments << @comments_class.create(:text => '1')
      post.comments << @comments_class.create(:text => '2')
      post.comments << @comments_class.create(:text => '3')

      post.comments.count.should == 3
      post.comments.destroy_all(:text => '1')
      post.comments.count.should == 2

      post.comments.destroy_all
      post.comments.count.should == 0
    end

    it "should work with dealiased keys" do
      @obj = @dealiased_keys_class.new(:foo => "foo")
      @obj.save!
      @obj.reload
      @obj.foo.should == "foo"

      @obj.foo = "bar"
      @obj.save!
      @obj.reload
      @obj.foo.should == "bar"
    end

    it "should be able to nullify one associations through re-assignment" do
      @post = @post_class.create
      @author = @author_class.new
      @post.author = @author

      @author.reload
      @author.authorable_id.should == @post.id

      @post.author = @author_class.new

      @author.reload
      @author.authorable_id.should be_nil
    end

    it "should update values set in before_create" do
      @klass.before_create do
        self.string_field = "Scott"
      end

      obj = @klass.new
      obj.save!

      obj.string_field.should == "Scott"
      obj.reload
      obj.string_field.should == "Scott"
    end

    it "should update values set in before_update" do
      @klass.before_update do
        self.string_field = "Scott"
      end

      obj = @klass.new
      obj.save!

      obj.save!
      obj.string_field.should == "Scott"
      obj.reload
      obj.string_field.should == "Scott"
    end

  end
end
