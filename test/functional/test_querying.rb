require 'test_helper'

class QueryingTesting < Test::Unit::TestCase
  def setup
    @document = Doc do
      key :first_name, String
      key :last_name, String
      key :age, Integer
      key :date, Date
    end
  end

  context ".query" do
    setup do
      @query = @document.query
    end

    should "set model to self" do
      @query.model.should == @document
    end

    should "always return new instance" do
      @document.query.should_not equal(@query)
    end

    should "apply options" do
      @document.query(:foo => 'bar')[:foo].should == 'bar'
    end
  end

  context ".criteria_hash" do
    setup do
      @hash = @document.criteria_hash
    end

    should "set object id keys on hash" do
      @hash.object_ids.should == [:_id]
    end

    should "always return new instance" do
      @document.criteria_hash.should_not equal(@hash)
    end

    should "apply provided criteria" do
      @document.criteria_hash(:foo => 'bar')[:foo].should == 'bar'
    end
  end

  context ".create (single document)" do
    setup do
      @doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
    end

    should "create a document in correct collection" do
      @document.count.should == 1
    end

    should "automatically set id" do
      @doc.id.should be_instance_of(BSON::ObjectId)
      @doc._id.should be_instance_of(BSON::ObjectId)
    end

    should "no longer be new?" do
      @doc.new?.should be_false
    end

    should "return instance of document" do
      @doc.should be_instance_of(@document)
      @doc.first_name.should == 'John'
      @doc.last_name.should == 'Nunemaker'
      @doc.age.should == 27
    end

    should "not fail if no attributes provided" do
      document = Doc()
      lambda { document.create }.should change { document.count }.by(1)
    end
  end

  context ".create (multiple documents)" do
    setup do
      @docs = @document.create([
        {:first_name => 'John', :last_name => 'Nunemaker', :age => '27'},
        {:first_name => 'Steve', :last_name => 'Smith', :age => '28'},
      ])
    end

    should "create multiple documents" do
      @document.count.should == 2
    end

    should "return an array of doc instances" do
      @docs.map do |doc|
        doc.should be_instance_of(@document)
      end
    end
  end

  context ".update (single document)" do
    setup do
      doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc = @document.update(doc._id, {:age => 40})
    end

    should "update attributes provided" do
      @doc.age.should == 40
    end

    should "not update existing attributes that were not set to update" do
      @doc.first_name.should == 'John'
      @doc.last_name.should == 'Nunemaker'
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

  context ".update (multiple documents)" do
    setup do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})

      @docs = @document.update({
        @doc1._id => {:age => 30},
        @doc2._id => {:age => 30},
      })
    end

    should "not create any new documents" do
      @document.count.should == 2
    end

    should "should return an array of doc instances" do
      @docs.map do |doc|
        doc.should be_instance_of(@document)
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

  context ".find" do
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

      should "work as arguments with string ids" do
        @document.find(@doc1._id.to_s, @doc2._id.to_s).should == [@doc1, @doc2]
      end

      should "work as array" do
        @document.find([@doc1._id, @doc2._id]).should == [@doc1, @doc2]
      end

      should "work as array with string ids" do
        @document.find([@doc1._id.to_s, @doc2._id.to_s]).should == [@doc1, @doc2]
      end

      should "compact not found when using find" do
        @document.find(@doc1._id, BSON::ObjectId.new.to_s).should == [@doc1]
      end

      should "raise error if not all found when using find!" do
        assert_raises(MongoMapper::DocumentNotFound) do
          @document.find!(@doc1._id, BSON::ObjectId.new.to_s)
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
      should "find all documents with options" do
        @document.all(:order => 'first_name').should == [@doc1, @doc3, @doc2]
        @document.all(:last_name => 'Nunemaker', :order => 'age desc').should == [@doc1, @doc3]
      end
    end

    context "#first" do
      should "find first document with options" do
        @document.first(:order => 'first_name').should == @doc1
        @document.first(:age => 28).should == @doc2
      end
    end

    context "#last" do
      should "find last document with options" do
        @document.last(:order => 'age').should == @doc2
        @document.last(:order => 'age', :age => 28).should == @doc2
      end
    end

    context "#find_each" do
      should "yield all documents found based on options" do
        yield_documents = []
        @document.find_each(:order => "first_name") {|doc| yield_documents << doc }
        yield_documents.should == [@doc1, @doc3, @doc2]

        yield_documents = []
        @document.find_each(:last_name => 'Nunemaker', :order => 'age desc') {|doc| yield_documents << doc }
        yield_documents.should == [@doc1, @doc3]
      end
    end
  end # finding documents

  context ".find_by_id" do
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

  context ".first_or_create" do
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

    should "disregard non-keys when creating, but use them in the query" do
      assert_nothing_raised do
        @document.create(:first_name => 'John', :age => 9)
        lambda {
          @document.first_or_create(:first_name => 'John', :age.gt => 10).first_name.should == 'John'
        }.should change { @document.count }.by(1)
      end
    end
  end

  context ".first_or_new" do
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

    should "disregard non-keys when initializing, but use them in the query" do
      assert_nothing_raised do
        @document.create(:first_name => 'John', :age => 9)
        @document.first_or_new(:first_name => 'John', :age.gt => 10).first_name.should == 'John'
      end
    end
  end

  context ".delete (single document)" do
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

  context ".delete (multiple documents)" do
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

  context ".delete_all" do
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

  context ".destroy (single document)" do
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

  context ".destroy (multiple documents)" do
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

  context ".destroy_all" do
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

  context ".count" do
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

  context ".size" do
    should "return 0 if no documents" do
      @document.count.should == 0
    end

    should "return the number of documents" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.count.should == 3
    end
  end

  context ".empty?" do
    should "be true if no documents" do
      @document.empty?.should be_true
    end

    should "be false if documents present" do
      @doc = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @document.empty?.should be_false
    end
  end

  context ".exists?" do
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

  context "to_a" do
    should "return an array" do
      @document.to_a.class.should == Array
    end

    should "return everything" do
      @doc1 = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
      @doc2 = @document.create({:first_name => 'Steve', :last_name => 'Smith', :age => '28'})
      @doc3 = @document.create({:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26'})
      @document.to_a.size.should == 3
    end
  end

  context ".where" do
    setup do
      @doc1 = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith',     :age => '28')
      @doc3 = @document.create(:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26')
      @query = @document.where(:last_name => 'Nunemaker')
    end

    should "fetch documents when kicker called" do
      docs = @query.all
      docs.should include(@doc1)
      docs.should include(@doc3)
      docs.should_not include(@doc2)
    end

    should "be chainable" do
      @query.sort(:age).first.should == @doc3
    end
  end

  context ".fields" do
    setup do
      @doc1 = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith',     :age => '28')
      @doc3 = @document.create(:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26')
      @query = @document.fields(:age)
    end

    should "fetch documents when kicker called" do
      docs = @query.all
      docs.should include(@doc1)
      docs.should include(@doc3)
      docs.should include(@doc2)
      docs.each do |doc|
        doc.age.should_not    be_nil
        doc.first_name.should be_nil # key was not loaded
        doc.last_name.should  be_nil # key was not loaded
      end
    end

    should "be chainable" do
      @query.sort(:age).all.map(&:age).should == [26, 27, 28]
    end
  end

  context ".limit" do
    setup do
      @doc1 = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith',     :age => '28')
      @doc3 = @document.create(:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26')
      @query = @document.limit(2)
    end

    should "fetch documents when kicker called" do
      docs = @query.all
      docs.size.should == 2
    end

    should "be chainable" do
      result = [26, 27]
      @query.sort(:age).all.map(&:age).should == result
      @query.count.should > result.size
    end
  end

  context ".skip" do
    setup do
      @doc1 = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith',     :age => '28')
      @doc3 = @document.create(:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26')
      @query = @document.skip(1)
    end

    should "fetch documents when kicker called" do
      docs = @query.all
      docs.size.should == 2 # skipping 1 out of 3
    end

    should "be chainable" do
      result = [27, 28]
      @query.sort(:age).all.map(&:age).should == result
      @query.count.should > result.size
    end
  end

  context ".sort" do
    setup do
      @doc1 = @document.create(:first_name => 'John',  :last_name => 'Nunemaker', :age => '27')
      @doc2 = @document.create(:first_name => 'Steve', :last_name => 'Smith',     :age => '28')
      @doc3 = @document.create(:first_name => 'Steph', :last_name => 'Nunemaker', :age => '26')
      @query = @document.sort(:age)
    end

    should "fetch documents when kicker called" do
      @query.all.should == [@doc3, @doc1, @doc2]
    end

    should "be chainable" do
      result = [28]
      @query.skip(2).all.map(&:age).should == result
      @query.count.should > result.size
    end
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
      @doc.id.should be_instance_of(BSON::ObjectId)
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

  context "#update_attribute" do
    setup do
      @doc = @document.create(:first_name => 'John', :age => '27')
    end

    should "accept symbols as keys" do
      @doc.update_attribute(:first_name, 'Chris').should be_true
      @doc.reload.first_name.should == 'Chris'
    end

    should "update the attribute" do
      @doc.update_attribute('first_name', 'Chris').should be_true
      @doc.reload.first_name.should == 'Chris'
    end

    should "update the attribute without invoking validations" do
      @document.key :name, String, :required => true

      @doc.expects(:valid?).never
      @doc.update_attribute('name', '').should be_true
      @doc.reload.name.should == ''
      @document.count.should == 1
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
      @doc.id.should be_instance_of(BSON::ObjectId)
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
      end
      @document.ensure_index :name, :unique => true
    end
    teardown { drop_indexes(@document) }

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
      @document = Doc { key :name, String }
      @document.ensure_index :name, :unique => true
    end
    teardown { drop_indexes(@document) }

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
end