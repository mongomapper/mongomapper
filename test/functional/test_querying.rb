require 'test_helper'

class QueryingTesting < Test::Unit::TestCase
  def setup
    @document = Doc do
      set_collection_name 'users'

      key :first_name, String
      key :last_name, String
      key :age, Integer
      key :date, Date
    end
  end
  
  context ".create (single document)" do
    setup do
      @doc_instance = @document.create({:first_name => 'John', :last_name => 'Nunemaker', :age => '27'})
    end

    should "create a document in correct collection" do
      @document.count.should == 1
    end

    should "automatically set id" do
      @doc_instance.id.should be_instance_of(BSON::ObjectID)
      @doc_instance._id.should be_instance_of(BSON::ObjectID)
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

  context ".create (multiple documents)" do
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

  context ".update (single document)" do
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

  context ".update (multiple documents)" do
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
        @document.find(@doc1._id, BSON::ObjectID.new.to_s).should == [@doc1]
      end

      should "raise error if not all found when using find!" do
        assert_raises(MongoMapper::DocumentNotFound) do
          @document.find!(@doc1._id, BSON::ObjectID.new.to_s)
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

    should "disregard non-keys when creating, but use them in the query" do
      assert_nothing_raised do
        @document.create(:first_name => 'John', :age => 9)
        lambda {
          @document.first_or_create(:first_name => 'John', :age.gt => 10).first_name.should == 'John'
        }.should change { @document.count }.by(1)
      end
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
end