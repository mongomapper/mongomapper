require 'test_helper'
require 'models'

class DocumentTest < Test::Unit::TestCase
  def setup
    @document = Doc do
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
      @id = BSON::ObjectId.new
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
