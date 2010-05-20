require 'test_helper'
require 'models'

class DocumentTest < Test::Unit::TestCase
  def setup
    @document = Doc do
      set_collection_name 'users'

      key :first_name, String
      key :last_name, String
      key :age, Integer
      key :date, Date
    end
  end

  context "array key" do
    setup do
      @document.key :tags, Array
    end

    should "give correct default" do
      doc = @document.new
      doc.tags.should == []
    end

    should "work with assignment" do
      doc = @document.new
      doc.tags = %w(foo bar)
      doc.tags.should == %w(foo bar)
    end

    should "work with assignment after saving" do
      doc = @document.new
      doc.tags = %w(foo bar)
      doc.save
      doc.tags.should == %w(foo bar)
      doc.reload.tags.should == %w(foo bar)
    end

    should "work with assignment then <<" do
      doc = @document.new
      doc.tags = []
      doc.tags << "foo"
      doc.tags.should == ["foo"]
    end

    should "work with <<" do
      doc = @document.new
      doc.tags << "foo"
      doc.tags.should == ["foo"]
    end

    should "work with << then save" do
      doc = @document.new
      doc.tags << "foo"
      doc.tags << "bar"
      doc.save
      doc.tags.should == %w(foo bar)
      doc.reload.tags.should == %w(foo bar)
    end
  end

  context "hash key" do
    setup do
      @document.key :foo, Hash
    end

    should "give correct default" do
      doc = @document.new
      doc.foo.should == {}
    end

    should "work with []=" do
      doc = @document.new
      doc.foo["quux"] = "bar"
      doc.foo["quux"].should == "bar"
      doc.foo.should == { "quux" => "bar" }
    end

    should "work with indifferent access" do
      doc = @document.new
      doc.foo = {:baz => 'bar'}
      doc.foo[:baz].should == 'bar'
      doc.foo['baz'].should == 'bar'
    end

    should "work with indifferent access after save" do
      doc = @document.new
      doc.foo = {:baz => 'bar'}
      doc.save

      doc = doc.reload
      doc.foo[:baz].should == 'bar'
      doc.foo['baz'].should == 'bar'
    end
  end

  context "custom type key with default" do
    setup do
      @document.key :window, WindowSize, :default => WindowSize.new(600, 480)
    end

    should "default to default" do
      doc = @document.new
      doc.window.should == WindowSize.new(600, 480)

    end

    should "save and load from mongo" do
      doc = @document.new
      doc.save

      doc = doc.reload
      doc.window.should == WindowSize.new(600, 480)
    end
  end

  context "key with proc default value" do
    setup do
      @document.key :proc_default, String, :default => lambda { return 'string' }
    end

    should "detect and run proc default" do
      doc = @document.new
      doc.proc_default.should == 'string'
    end

    should "save and load from mongo" do
      doc = @document.create
      doc = doc.reload
      doc.proc_default.should == 'string'
    end
  end

  should "have instance method for collection" do
    @document.new.collection.name.should == @document.collection.name
  end

  should "have instance method for database" do
    @document.new.database.should == @document.database
  end

  context "#update_attributes (new document)" do
    setup do
      @doc = @document.new(:first_name => 'John', :age => '27')
      @doc.update_attributes(:first_name => 'Johnny', :age => 30)
    end

    should "insert document into the collection" do
      @document.count.should == 1
    end

    should "assign an id for the document" do
      @doc.id.should be_instance_of(BSON::ObjectID)
    end

    should "save attributes" do
      @doc.first_name.should == 'Johnny'
      @doc.age.should == 30
    end

    should "update attributes in the database" do
      doc = @doc.reload
      doc.should == @doc
      doc.first_name.should == 'Johnny'
      doc.age.should == 30
    end

    should "allow updating custom attributes" do
      @doc.update_attributes(:gender => 'mALe')
      @doc.reload.gender.should == 'mALe'
    end
  end

  context "#update_attributes (existing document)" do
    setup do
      @doc = @document.create(:first_name => 'John', :age => '27')
      @doc.update_attributes(:first_name => 'Johnny', :age => 30)
    end

    should "not insert document into collection" do
      @document.count.should == 1
    end

    should "update attributes" do
      @doc.first_name.should == 'Johnny'
      @doc.age.should == 30
    end

    should "update attributes in the database" do
      doc = @doc.reload
      doc.first_name.should == 'Johnny'
      doc.age.should == 30
    end
  end

  context "#update_attributes (return value)" do
    setup do
      @document.key :foo, String, :required => true
    end

    should "be true if document valid" do
      @document.new.update_attributes(:foo => 'bar').should be_true
    end

    should "be false if document not valid" do
      @document.new.update_attributes({}).should be_false
    end
  end

  context "#save (new document)" do
    setup do
      @doc = @document.new(:first_name => 'John', :age => '27')
      @doc.save
    end

    should "insert document into the collection" do
      @document.count.should == 1
    end

    should "assign an id for the document" do
      @doc.id.should be_instance_of(BSON::ObjectID)
    end

    should "save attributes" do
      @doc.first_name.should == 'John'
      @doc.age.should == 27
    end

    should "update attributes in the database" do
      doc = @doc.reload
      doc.should == @doc
      doc.first_name.should == 'John'
      doc.age.should == 27
    end

    should "allow to add custom attributes to the document" do
      @doc = @document.new(:first_name => 'David', :age => '26', :gender => 'male', :tags => [1, "2"])
      @doc.save
      doc = @doc.reload
      doc.gender.should == 'male'
      doc.tags.should == [1, "2"]
    end

    should "allow to use custom methods to assign properties" do
      klass = Doc do
        key :name, String

        def realname=(value)
          self.name = value
        end
      end

      person = klass.new(:realname => 'David')
      person.save
      person.reload.name.should == 'David'
    end

    context "with key of type date" do
      should "save the date value as a Time object" do
        doc = @document.new(:first_name => 'John', :age => '27', :date => "2009-12-01")
        doc.save
        doc.date.should == Date.new(2009, 12, 1)
      end
    end
  end

  context "#save (existing document)" do
    setup do
      @doc = @document.create(:first_name => 'John', :age => '27')
      @doc.first_name = 'Johnny'
      @doc.age = 30
      @doc.save
    end

    should "not insert document into collection" do
      @document.count.should == 1
    end

    should "update attributes" do
      @doc.first_name.should == 'Johnny'
      @doc.age.should == 30
    end

    should "update attributes in the database" do
      doc = @doc.reload
      doc.first_name.should == 'Johnny'
      doc.age.should == 30
    end

    should "allow updating custom attributes" do
      @doc = @document.new(:first_name => 'David', :age => '26', :gender => 'male')
      @doc.gender = 'Male'
      @doc.save
      @doc.reload.gender.should == 'Male'
    end
  end

  context "#save (with validations off)" do
    setup do
      @document = Doc do
        key :name, String, :required => true
      end
    end

    should "insert invalid document" do
      doc = @document.new
      doc.expects(:valid?).never
      doc.save(:validate => false)
      @document.count.should == 1
    end
  end

  context "#save (with options)" do
    setup do
      @document = Doc do
        key :name, String
        set_collection_name 'test_indexes'
      end
      drop_indexes(@document)
      @document.ensure_index :name, :unique => true
    end

    should "allow passing safe" do
      @document.create(:name => 'John')
      assert_raises(Mongo::OperationFailure) do
        @document.new(:name => 'John').save(:safe => true)
      end
    end

    should "raise argument error if options has unsupported key" do
      assert_raises(ArgumentError) do
        @document.new.save(:foo => true)
      end
    end
  end

  context "#save! (with options)" do
    setup do
      @document = Doc do
        key :name, String
        set_collection_name 'test_indexes'
      end
      drop_indexes(@document)
      @document.ensure_index :name, :unique => true
    end

    should "allow passing safe" do
      @document.create(:name => 'John')
      assert_raises(Mongo::OperationFailure) do
        @document.new(:name => 'John').save!(:safe => true)
      end
    end

    should "raise argument error if options has unsupported key" do
      assert_raises(ArgumentError) do
        @document.new.save!(:foo => true)
      end
    end

    should "raise argument error if using validate as that would be pointless with save!" do
      assert_raises(ArgumentError) do
        @document.new.save!(:validate => false)
      end
    end
  end

  context "#destroy" do
    setup do
      @doc = @document.create(:first_name => 'John', :age => '27')
      @doc.destroy
    end

    should "remove the document from the collection" do
      @document.count.should == 0
    end
  end

  context "#delete" do
    setup do
      @doc1 = @document.create(:first_name => 'John', :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith', :age => '28')

      @document.class_eval do
        before_destroy :before_destroy_callback
        after_destroy :after_destroy_callback

        def history; @history ||= [] end
        def before_destroy_callback; history << :after_destroy end
        def after_destroy_callback;  history << :after_destroy end
      end

      @doc1.delete
    end

    should "remove document from collection" do
      @document.count.should == 1
    end

    should "not remove other documents" do
      @document.find(@doc2.id).should_not be(nil)
    end

    should "not call before/after destroy callbacks" do
      @doc1.history.should == []
    end
  end

  context "#destroyed?" do
    setup do
      @doc1 = @document.create(:first_name => 'John', :last_name => 'Nunemaker', :age => '27')
    end

    should "be true if deleted" do
      @doc1.delete
      assert @doc1.destroyed?
    end

    should "be true if destroyed" do
      @doc1.destroy
      assert @doc1.destroyed?
    end

    should "be false if not deleted or destroyed" do
      assert ! @doc1.destroyed?
    end
  end

  context "#persisted?" do
    setup do
      @doc = @document.new(:first_name => 'John', :last_name => 'Nunemaker', :age => '27')
    end

    should "be false if new" do
      @doc.should_not be_persisted
    end

    should "be false if destroyed" do
      @doc.save
      @doc.destroy
      @doc.should be_destroyed
      @doc.should_not be_persisted
    end

    should "be true if not new or destroyed" do
      @doc.save
      @doc.should be_persisted
    end
  end

  context "#reload" do
    setup do
      @foo_class = Doc do
        key :name
      end

      @bar_class = EDoc do
        key :name
      end

      @document.many :foos, :class => @foo_class
      @document.many :bars, :class => @bar_class

      @instance = @document.create({
        :age => 39,
        :foos => [@foo_class.new(:name => '1')],
        :bars => [@bar_class.new(:name => '1')],
      })
    end

    should "reload keys from the database" do
      @instance.age = 37
      @instance.age.should == 37
      @instance.reload
      @instance.age.should == 39
    end

    should "reset all associations" do
      @instance.foos.expects(:reset).at_least_once
      @instance.bars.expects(:reset).at_least_once
      @instance.reload
    end

    should "reinstantiate embedded associations" do
      @instance.reload
      @instance.bars.first.name.should == '1'
    end

    should "return self" do
      @instance.reload.object_id.should == @instance.object_id
    end

    should "raise DocumentNotFound if not found" do
      @instance.destroy
      assert_raises(MongoMapper::DocumentNotFound) { @instance.reload }
    end
  end

  context "database has keys not defined in model" do
    setup do
      @id = BSON::ObjectID.new
      @document.collection.insert({
        :_id            => @id,
        :first_name     => 'John',
        :last_name      => 'Nunemaker',
        :age            => 27,
        :favorite_color => 'red',
        :skills         => ['ruby', 'rails', 'javascript', 'xhtml', 'css']
      })
    end

    should "assign all keys from database" do
      doc = @document.find(@id)
      doc.first_name.should == 'John'
      doc.last_name.should == 'Nunemaker'
      doc.age.should == 27
      doc.favorite_color.should == 'red'
      doc.skills.should == ['ruby', 'rails', 'javascript', 'xhtml', 'css']
    end
  end
end
