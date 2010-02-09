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

  context "ClassMethods#create (single document)" do
    setup do
      @doc_instance = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
    end

    should "create a document in correct collection" do
      @document.count.should == 1
    end

    should "automatically set id" do
      @doc_instance.id.should be_instance_of(Mongo::ObjectID)
      @doc_instance._id.should be_instance_of(Mongo::ObjectID)
    end

    should "no longer be new?" do
      @doc_instance.new?.should be_false
    end

    should "return instance of document" do
      @doc_instance.should be_instance_of(@document)
      @doc_instance.first_name.should == 'John'
      @doc_instance.last_name.should == 'Nunemaker'
      @doc_instance.age.should == 27
    end
    
    should "not fail if no attributes provided" do
      document = Doc()
      lambda { document.create }.should change { document.count }.by(1)
    end
  end

  context "ClassMethods#create (multiple documents)" do
    setup do
      @doc_instances = @document.create([
        {:first_name => 'John', :last_name => 'Nunemaker', :age => '27'},
        {:first_name => 'Steve', :last_name => 'Smith', :age => '28'},
      ])
    end

    should "create multiple documents" do
      @document.count.should == 2
    end

    should "return an array of doc instances" do
      @doc_instances.map do |doc_instance|
        doc_instance.should be_instance_of(@document)
      end
    end
  end

  context "ClassMethods#update (single document)" do
    setup do
      doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc_instance = @document.update(doc._id, {:age => 40})
    end

    should "update attributes provided" do
      @doc_instance.age.should == 40
    end

    should "not update existing attributes that were not set to update" do
      @doc_instance.first_name.should == 'John'
      @doc_instance.last_name.should == 'Nunemaker'
    end

    should "not create new document" do
      @document.count.should == 1
    end
    
    should "raise error if not provided id" do
      doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      lambda { @document.update }.should raise_error(ArgumentError)
    end
    
    should "raise error if not provided attributes" do
      doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      lambda { @document.update(doc._id) }.should raise_error(ArgumentError)
      lambda { @document.update(doc._id, [1]) }.should raise_error(ArgumentError)
    end
  end

  context "ClassMethods#update (multiple documents)" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})

      @doc_instances = @document.update({
        @doc1._id => {:age => 30},
        @doc2._id => {:age => 30},
      })
    end

    should "not create any new documents" do
      @document.count.should == 2
    end

    should "should return an array of doc instances" do
      @doc_instances.map do |doc_instance|
        doc_instance.should be_instance_of(@document)
      end
    end

    should "update the documents" do
      @document.find(@doc1._id).age.should == 30
      @document.find(@doc2._id).age.should == 30
    end
    
    should "raise error if not a hash" do
      lambda { @document.update([1, 2]) }.should raise_error(ArgumentError)
    end
  end

  context "ClassMethods#find" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
    end

    should "return nil if nothing provided for find" do
      @document.find.should be_nil
    end

    should "raise document not found if nothing provided for find!" do
      assert_raises(MongoMapper::DocumentNotFound) do
        @document.find!
      end
    end
    
    should "raise error if trying to find with :all, :first, or :last" do
      [:all, :first, :last].each do |m|
        assert_raises(ArgumentError) { @document.find(m) }
      end

      [:all, :first, :last].each do |m|
        assert_raises(ArgumentError) { @document.find!(m) }
      end
    end

    context "(with a single id)" do
      should "work" do
        @document.find(@doc1._id).should == @doc1
      end

      should "return nil if document not found with find" do
        @document.find(123).should be_nil
      end

      should "raise error if document not found with find!" do
        assert_raises(MongoMapper::DocumentNotFound) { @document.find!(123) }
      end
    end

    context "(with multiple id's)" do
      should "work as arguments" do
        @document.find(@doc1._id, @doc2._id).should == [@doc1, @doc2]
      end

      should "work as array" do
        @document.find([@doc1._id, @doc2._id]).should == [@doc1, @doc2]
      end

      should "compact not found when using find" do
        @document.find(@doc1._id, 1234).should == [@doc1]
      end

      should "raise error if not all found when using find!" do
        assert_raises(MongoMapper::DocumentNotFound) do
          @document.find!(@doc1._id, 1234)
        end
      end

      should "return array if array with one element" do
        @document.find([@doc1._id]).should == [@doc1]
      end
    end

    should "be able to find using condition auto-detection" do
      @document.first(:first_name => 'John').should == @doc1
      @document.all(:last_name => 'Nunemaker', :order => 'age desc').should == [@doc1, @doc3]
    end

    context "#all" do
      should "find all documents based on criteria" do
        @document.all(:order => 'first_name').should == [@doc1, @doc3, @doc2]
        @document.all(:last_name => 'Nunemaker', :order => 'age desc').should == [@doc1, @doc3]
      end
    end

    context "#first" do
      should "find first document based on criteria" do
        @document.first(:order => 'first_name').should == @doc1
        @document.first(:age => 28).should == @doc2
      end
    end

    context "#last" do
      should "find last document based on criteria" do
        @document.last(:order => 'age').should == @doc2
        @document.last(:order => 'age', :age => 28).should == @doc2
      end

      should "raise error if no order provided" do
        lambda { @document.last() }.should raise_error
      end
    end

    context "#find_by..." do
      should "find document based on argument" do
        @document.find_by_first_name('John').should == @doc1
        @document.find_by_last_name('Nunemaker', :order => 'age desc').should == @doc1
        @document.find_by_age(27).should == @doc1
      end

      should "not raise error" do
        @document.find_by_first_name('Mongo').should be_nil
      end

      should "define a method for each key" do
        @document.methods(false).select { |e| e =~ /^find_by_/ }.size == @document.keys.size
      end
    end

    context "#find_each" do
      should "yield all documents found, based on criteria" do
        yield_documents = []
        @document.find_each(:order => "first_name") {|doc| yield_documents << doc }
        yield_documents.should == [@doc1, @doc3, @doc2]

        yield_documents = []
        @document.find_each(:last_name => 'Nunemaker', :order => 'age desc') {|doc| yield_documents << doc }
        yield_documents.should == [@doc1, @doc3]
      end
    end

    context "dynamic finders" do
      should "find document based on all arguments" do
        @document.find_by_first_name_and_last_name_and_age('John', 'Nunemaker', 27).should == @doc1
      end

      should "not find the document if an argument is wrong" do
        @document.find_by_first_name_and_last_name_and_age('John', 'Nunemaker', 28).should be_nil
      end

      should "find all documents based on arguments" do
        docs = @document.find_all_by_last_name('Nunemaker')
        docs.should be_kind_of(Array)
        docs.should include(@doc1)
        docs.should include(@doc3)
      end

      should "initialize document with given arguments" do
        doc = @document.find_or_initialize_by_first_name_and_last_name('David', 'Cuadrado')
        doc.should be_new
        doc.first_name.should == 'David'
      end

      should "not initialize document if document is found" do
        doc = @document.find_or_initialize_by_first_name('John')
        doc.should_not be_new
      end

      should "create document with given arguments" do
        doc = @document.find_or_create_by_first_name_and_last_name('David', 'Cuadrado')
        doc.should_not be_new
        doc.first_name.should == 'David'
      end

      should "raise error if document is not found when using !" do
        lambda {
          @document.find_by_first_name_and_last_name!(1,2)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end
  end # finding documents

  context "ClassMethods#find_by_id" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
    end

    should "be able to find by id" do
      @document.find_by_id(@doc1._id).should == @doc1
      @document.find_by_id(@doc2._id).should == @doc2
    end

    should "return nil if document not found" do
      @document.find_by_id(1234).should be_nil
    end
  end

  context "first_or_create" do
    should "find if exists" do
      created = @document.create(:first_name => 'John', :last_name => 'Nunemaker')
      lambda {
        found = @document.first_or_create(:first_name => 'John', :last_name => 'Nunemaker')
        found.should == created
      }.should_not change { @document.count }
    end

    should "create if not found" do
      lambda {
        created = @document.first_or_create(:first_name => 'John', :last_name => 'Nunemaker')
        created.first_name.should == 'John'
        created.last_name.should == 'Nunemaker'
      }.should change { @document.count }.by(1)
    end
  end

  context "first_or_new" do
    should "find if exists" do
      created = @document.create(:first_name => 'John', :last_name => 'Nunemaker')
      lambda {
        found = @document.first_or_new(:first_name => 'John', :last_name => 'Nunemaker')
        found.should == created
      }.should_not change { @document.count }
    end

    should "initialize if not found" do
      lambda {
        created = @document.first_or_new(:first_name => 'John', :last_name => 'Nunemaker')
        created.first_name.should == 'John'
        created.last_name.should == 'Nunemaker'
        created.should be_new
      }.should_not change { @document.count }
    end
  end

  context "ClassMethods#delete (single document)" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @document.delete(@doc1._id)
    end

    should "remove document from collection" do
      @document.count.should == 1
    end

    should "not remove other documents" do
      @document.find(@doc2._id).should_not be(nil)
    end
  end

  context "ClassMethods#delete (multiple documents)" do
    should "work with multiple arguments" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.delete(@doc1._id, @doc2._id)

      @document.count.should == 1
    end

    should "work with array as argument" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.delete([@doc1._id, @doc2._id])

      @document.count.should == 1
    end
  end

  context "ClassMethods#delete_all" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
    end

    should "remove all documents when given no conditions" do
      @document.delete_all
      @document.count.should == 0
    end

    should "only remove matching documents when given conditions" do
      @document.delete_all({:first_name => 'John'})
      @document.count.should == 2
    end

    should "convert the conditions to mongo criteria" do
      @document.delete_all(:age => [26, 27])
      @document.count.should == 1
    end
  end

  context "ClassMethods#destroy (single document)" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @document.destroy(@doc1._id)
    end

    should "remove document from collection" do
      @document.count.should == 1
    end

    should "not remove other documents" do
      @document.find(@doc2._id).should_not be(nil)
    end
  end

  context "ClassMethods#destroy (multiple documents)" do
    should "work with multiple arguments" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.destroy(@doc1._id, @doc2._id)
      
      @document.count.should == 1
    end

    should "work with array as argument" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.destroy([@doc1._id, @doc2._id])

      @document.count.should == 1
    end
  end

  context "ClassMethods#destroy_all" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
    end

    should "remove all documents when given no conditions" do
      @document.destroy_all
      @document.count.should == 0
    end

    should "only remove matching documents when given conditions" do
      @document.destroy_all(:first_name => 'John')
      @document.count.should == 2
      @document.destroy_all(:age => 26)
      @document.count.should == 1
    end

    should "convert the conditions to mongo criteria" do
      @document.destroy_all(:age => [26, 27])
      @document.count.should == 1
    end
  end

  context "ClassMethods#count" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
    end

    should "count all with no arguments" do
      @document.count.should == 3
    end

    should "return 0 if there are no documents in the collection" do
      @document.delete_all
      @document.count.should == 0
    end

    should "return 0 if the collection does not exist" do
      klass = Doc do
        set_collection_name 'foobarbazwickdoesnotexist'
      end

      klass.count.should == 0
    end

    should "return count for matching documents if conditions provided" do
      @document.count(:age => 27).should == 1
    end

    should "convert the conditions to mongo criteria" do
      @document.count(:age => [26, 27]).should == 2
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
      @doc.id.should be_instance_of(Mongo::ObjectID)
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
      @doc.id.should be_instance_of(Mongo::ObjectID)
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
        doc = @document.new(:first_name => 'John', :age => '27', :date => "12/01/2009")
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
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      
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

  context "Single collection inheritance" do
    setup do
      class ::DocParent
        include MongoMapper::Document
        key :_type, String
        key :name, String
      end
      DocParent.collection.remove

      class ::DocDaughter < ::DocParent; end
      class ::DocSon < ::DocParent; end
      class ::DocGrandSon < ::DocSon; end
      
      DocSon.many :children, :class_name => 'DocGrandSon'

      @parent = DocParent.new({:name => "Daddy Warbucks"})
      @daughter = DocDaughter.new({:name => "Little Orphan Annie"})
    end

    teardown do
      Object.send :remove_const, 'DocParent'   if defined?(::DocParent)
      Object.send :remove_const, 'DocDaughter' if defined?(::DocDaughter)
      Object.send :remove_const, 'DocSon'      if defined?(::DocSon)
      Object.send :remove_const, 'DocGrandSon' if defined?(::DocGrandSon)
    end

    should "use the same collection in the subclass" do
      DocDaughter.collection.name.should == DocParent.collection.name
    end

    should "assign the class name into the _type property" do
      @parent._type.should == 'DocParent'
      @daughter._type.should == 'DocDaughter'
    end

    should "load the document with the assigned type" do
      @parent.save
      @daughter.save

      collection = DocParent.all
      collection.size.should == 2
      collection.first.should be_kind_of(DocParent)
      collection.first.name.should == "Daddy Warbucks"
      collection.last.should be_kind_of(DocDaughter)
      collection.last.name.should == "Little Orphan Annie"
    end

    should "gracefully handle when the type can't be constantized" do
      doc = DocParent.new(:name => 'Nunes')
      doc._type = 'FoobarBaz'
      doc.save

      collection = DocParent.all
      collection.last.should == doc
      collection.last.should be_kind_of(DocParent)
    end

    should "find scoped to class" do
      john = DocSon.create(:name => 'John')
      steve = DocSon.create(:name => 'Steve')
      steph = DocDaughter.create(:name => 'Steph')
      carrie = DocDaughter.create(:name => 'Carrie')

      DocGrandSon.all(:order => 'name').should  == []
      DocSon.all(:order => 'name').should       == [john, steve]
      DocDaughter.all(:order => 'name').should  == [carrie, steph]
      DocParent.all(:order => 'name').should    == [carrie, john, steph, steve]
    end
    
    should "work with nested hash conditions" do
      john = DocSon.create(:name => 'John')
      steve = DocSon.create(:name => 'Steve')
      DocSon.all(:name => {'$ne' => 'Steve'}).should == [john]
    end

    should "raise error if not found scoped to class" do
      john = DocSon.create(:name => 'John')
      steph = DocDaughter.create(:name => 'Steph')

      lambda {
        DocSon.find!(steph._id)
      }.should raise_error(MongoMapper::DocumentNotFound)
    end

    should "not raise error for find with parent" do
      john = DocSon.create(:name => 'John')

      DocParent.find!(john._id).should == john
    end

    should "count scoped to class" do
      john = DocSon.create(:name => 'John')
      steve = DocSon.create(:name => 'Steve')
      steph = DocDaughter.create(:name => 'Steph')
      carrie = DocDaughter.create(:name => 'Carrie')

      DocGrandSon.count.should  == 0
      DocSon.count.should       == 2
      DocDaughter.count.should  == 2
      DocParent.count.should    == 4
    end

    should "know if it is single_collection_inherited?" do
      DocParent.single_collection_inherited?.should be_false

      DocDaughter.single_collection_inherited?.should be_true
      DocSon.single_collection_inherited?.should be_true
    end

    should "know if single_collection_inherited_superclass?" do
      DocParent.single_collection_inherited_superclass?.should be_false

      DocDaughter.single_collection_inherited_superclass?.should be_true
      DocSon.single_collection_inherited_superclass?.should be_true
      DocGrandSon.single_collection_inherited_superclass?.should be_true
    end

    should "not be able to destroy each other" do
      john = DocSon.create(:name => 'John')
      steph = DocDaughter.create(:name => 'Steph')

      lambda {
        DocSon.destroy(steph._id)
      }.should raise_error(MongoMapper::DocumentNotFound)
    end

    should "not be able to delete each other" do
      john = DocSon.create(:name => 'John')
      steph = DocDaughter.create(:name => 'Steph')

      lambda {
        DocSon.delete(steph._id)
      }.should_not change { DocParent.count }
    end

    should "be able to destroy using parent" do
      john = DocSon.create(:name => 'John')
      steph = DocDaughter.create(:name => 'Steph')

      lambda {
        DocParent.destroy_all
      }.should change { DocParent.count }.by(-2)
    end

    should "be able to delete using parent" do
      john = DocSon.create(:name => 'John')
      steph = DocDaughter.create(:name => 'Steph')

      lambda {
        DocParent.delete_all
      }.should change { DocParent.count }.by(-2)
    end
    
    should "be able to reload parent inherited class" do
      brian = DocParent.create(:name => 'Brian')
      brian.name = 'B-Dawg'
      brian.reload
      brian.name.should == 'Brian'
    end
  end

  context "timestamping" do
    setup do
      @klass = Doc do
        set_collection_name 'users'

        key :first_name, String
        key :last_name, String
        key :age, Integer
        key :date, Date
      end
      @klass.timestamps!
    end

    should "set created_at and updated_at on create" do
      doc = @klass.new(:first_name => 'John', :age => 27)
      doc.created_at.should be(nil)
      doc.updated_at.should be(nil)
      doc.save
      doc.created_at.should_not be(nil)
      doc.updated_at.should_not be(nil)
    end
    
    should "not overwrite created_at if it already exists" do
      original_created_at = 1.month.ago
      doc = @klass.new(:first_name => 'John', :age => 27, :created_at => original_created_at)
      doc.created_at.to_i.should == original_created_at.to_i
      doc.updated_at.should be_nil
      doc.save
      doc.created_at.to_i.should == original_created_at.to_i
      doc.updated_at.should_not be_nil
    end

    should "set updated_at on field update but leave created_at alone" do
      doc = @klass.create(:first_name => 'John', :age => 27)
      old_created_at = doc.created_at
      old_updated_at = doc.updated_at
      doc.first_name = 'Johnny'

      Timecop.freeze(Time.now + 5.seconds) do
        doc.save
      end

      doc.created_at.should == old_created_at
      doc.updated_at.should_not == old_updated_at
    end

    should "set updated_at on document update but leave created_at alone" do
      doc = @klass.create(:first_name => 'John', :age => 27)
      old_created_at = doc.created_at
      old_updated_at = doc.updated_at

      Timecop.freeze(Time.now + 5.seconds) do
        @klass.update(doc._id, { :first_name => 'Johnny' })
      end

      doc = doc.reload
      doc.created_at.should == old_created_at
      doc.updated_at.should_not == old_updated_at
    end
  end

  context "userstamping" do
    setup do
      @document.userstamps!
    end
    
    should "add creator_id key" do
      @document.keys.keys.should include('creator_id')
    end
    
    should "add updater_id key" do
      @document.keys.keys.should include('updater_id')
    end
    
    should "add belongs_to creator" do
      @document.associations.keys.should include('creator')
    end
    
    should "add belongs_to updater" do
      @document.associations.keys.should include('updater')
    end
  end

  context "#exists?" do
    setup do
      @doc = @document.create(:first_name => "James", :age => 27)
    end

    should "be true when at least one document exists" do
      @document.exists?.should == true
    end

    should "be false when no documents exist" do
      @doc.destroy
      @document.exists?.should == false
    end

    should "be true when at least one document exists that matches the conditions" do
      @document.exists?(:first_name => "James").should == true
    end

    should "be false when no documents exist with the provided conditions" do
      @document.exists?(:first_name => "Jean").should == false
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
      @id = Mongo::ObjectID.new
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

  context "Indexing" do
    setup do
      drop_indexes(@document)
    end

    should "allow creating index for a key" do
      @document.ensure_index :first_name
      @document.should have_index('first_name_1')
    end

    should "allow creating unique index for a key" do
      @document.ensure_index :first_name, :unique => true
      @document.should have_index('first_name_1')
    end

    should "allow creating index on multiple keys" do
      @document.ensure_index [[:first_name, 1], [:last_name, -1]]
      
      # order is different for different versions of ruby so instead of
      # just checking have_index('first_name_1_last_name_-1') I'm checking
      # the values of the indexes to make sure the index creation was successful
      @document.collection.index_information.detect do |index|
        keys = index[1]
        keys.include?(['first_name', 1]) && keys.include?(['last_name', -1])
      end.should_not be_nil
    end

    should "work with :index shortcut when defining key" do
      @document.key :father, String, :index => true
      @document.should have_index('father_1')
    end
  end
end
