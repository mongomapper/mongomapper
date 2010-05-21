require 'test_helper'

class QueryTest < Test::Unit::TestCase
  include MongoMapper

  should "initialize with model" do
    model = Doc()
    Query.new(model).model.should == model
  end

  context "#query" do
    setup do
      @model = Doc do
        key :room_id, ObjectId
      end
      @query = Query.new(@model)
    end

    should "memoize" do
      @query.query.should equal(@query.query)
    end

    should "set object id keys" do
      @query.query.object_ids.should == [:room_id, :_id]
    end

    should "set collection to models collection" do
      @query.query.collection.name.should == @model.collection.name
    end
  end

  context "A Query" do
    setup do
      @model = Doc do
        key :room_id, ObjectId
      end
      @query = Query.new(@model)
    end

    should "delegate to_hash to #query" do
      @query.query.expects(:to_hash)
      @query.to_hash
    end

    should "delegate [] to #query" do
      @query.query.expects(:[]).with(:foo)
      @query[:foo]
    end

    should "delegate []= to #query" do
      @query.query.expects(:[]=).with(:foo, 'bar')
      @query[:foo] = 'bar'
    end

    should "delegate update to #query and return self" do
      @query.query.expects(:update).with(:foo => 'bar')
      @query.update(:foo => 'bar').should equal(@query)
    end

    should "delegate where to #query and return self" do
      @query.query.expects(:where).with(:name => 'John')
      @query.where(:name => 'John').should equal(@query)
    end

    should "delegate fields to #query and return self" do
      @query.query.expects(:fields).with(:name => true)
      @query.fields(:name => true).should equal(@query)
    end

    should "delegate limit to #query and return self" do
      @query.query.expects(:limit).with(10)
      @query.limit(10).should equal(@query)
    end

    should "delegate skip to #query and return self" do
      @query.query.expects(:skip).with(10)
      @query.skip(10).should equal(@query)
    end

    should "delegate sort to #query and return self" do
      @query.query.expects(:sort).with(:name)
      @query.sort(:name).should equal(@query)
    end

    should "delegate reverse to #query and return self" do
      @query.query.expects(:reverse)
      @query.reverse.should equal(@query)
    end

    should "delegate count to #query" do
      @query.query.expects(:count)
      @query.count
    end

    should "delegate simple? to #query" do
      @query.query.expects(:simple?)
      @query.simple?
    end

    should "delegate fields? to #query" do
      @query.query.expects(:fields?)
      @query.fields?
    end
  end

  context "#all" do
    setup do
      @model = Doc() { key :name, String }
      @query = Query.new(@model)
      @model.create(:name => 'John')
      @model.create(:name => 'Steve')
    end

    should "return all documents as instances of the model" do
      @query.all.each do |instance|
        instance.should be_instance_of(@model)
      end
    end

    should "work with options" do
      docs = @query.all(:name => 'John')
      docs.first.name.should == 'John'
    end

    should_eventually "not modify original query when using options" do
      docs = @query.all(:name => 'John')
      @query[:name].should be_nil
    end
  end

  context "#first" do
    setup do
      @model = Doc() { key :name, String }
      @query = Query.new(@model)
      @model.create(:name => 'John')
      @model.create(:name => 'Steve')
    end

    should "return an instance of the model" do
      @query.update(:name => 'John').first.should be_instance_of(@model)
    end

    should "work with options" do
      @query.first(:name => 'John').name.should == 'John'
    end

    should_eventually "not modify original query when using options" do
      @query.first(:name => 'John')
      @query[:name].should be_nil
    end
  end

  context "#last" do
    setup do
      @model = Doc() { key :name, String }
      @query = Query.new(@model)
      @model.create(:name => 'John')
      @model.create(:name => 'Steve')
    end

    should "return an instance of the model" do
      @query.update(:sort => :name).last.should be_instance_of(@model)
    end

    should "work with options" do
      @query.last(:sort => :name).name.should == 'Steve'
    end

    should_eventually "not modify original query when using options" do
      @query.last(:sort => :name)
      @query[:sort].should be_nil
    end
  end
end