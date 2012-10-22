require 'test_helper'
require 'models'

class EmbeddedDocumentTest < Test::Unit::TestCase
  def setup
    @klass = Doc('Person') do
      key :name, String
    end

    @pet_klass = EDoc('Pet') do
      key :name, String
    end

    @klass.many :pets, :class => @pet_klass

    @address_class = EDoc('Address') do
      key :city, String
      key :state, String
    end
  end

  context "Saving a document with a key that is an embedded document" do
    setup do
      @klass.key :foo, @address_class
    end

    should "embed embedded document" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.create(:foo => address)
      doc.foo.city.should == 'South Bend'
      doc.foo.state.should == 'IN'

      doc = doc.reload
      doc.foo.city.should == 'South Bend'
      doc.foo.state.should == 'IN'
    end

    should "assign _parent_document and _root_document" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      address._parent_document.should be_nil
      doc = @klass.create(:foo => address)
      address._parent_document.should be(doc)
      address._root_document.should be(doc)
    end

    should "assign _parent_document and _root_document when loading" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.create(:foo => address)
      doc.reload
      doc.foo._parent_document.should be(doc)
      doc.foo._root_document.should be(doc)
    end
  end

  should "correctly instantiate single collection inherited embedded documents" do
    document = Doc('Foo') do
      key :message, Message
    end

    doc1 = document.create(:message => Enter.new)
    doc1.reload.message.class.should be(Enter)
  end

  context "new? (embedded key)" do
    setup do
      @klass.key :foo, @address_class
    end

    should "be true until document is created" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      address.new?.should be_true
    end

    should "be false after document is saved" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      doc.save
      doc.foo.new?.should be_false
    end

    should "be false when loaded from database" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      doc.save

      doc.reload
      doc.foo.new?.should be_false
    end
  end

  context "new? (embedded many association)" do
    setup do
      @doc = @klass.new(:pets => [{:name => 'poo bear'}])
    end

    should "be true until document is saved" do
      @doc.should be_new
      @doc.pets.first.should be_new
    end

    should "be false after document is saved" do
      @doc.save
      @doc.pets.first.should_not be_new
    end

    should "be false when loaded from database" do
      @doc.save
      @doc.pets.first.should_not be_new
      @doc.reload
      @doc.pets.first.should_not be_new
    end

    should "be true until existing document is saved" do
      @doc.save
      pet = @doc.pets.build(:name => 'Rasmus')
      pet.new?.should be_true
      @doc.save
      pet.new?.should be_false
    end
  end

  context "new? (nested embedded many association)" do
    setup do
      @pet_klass.many :addresses, :class=> @address_class
      @doc = @klass.new
      @doc.pets.build(:name => 'Rasmus')
      @doc.save
    end

    should "be true until existing document is saved" do
      address = @doc.pets.first.addresses.build(:city => 'Holland', :state => 'MI')
      address.new?.should be_true
      @doc.save
      address.new?.should be_false
    end
  end

  context "new? (embedded one association)" do
    setup do
      @klass.one :address, :class => @address_class
      @doc = @klass.new
    end

    should "be true until existing document is saved" do
      @doc.save
      @doc.build_address(:city => 'Holland', :state => 'MI')
      @doc.address.new?.should be_true
      @doc.save
      @doc.address.new?.should be_false
    end
  end

  context "new? (nested embedded one association)" do
    setup do
      @pet_klass.one :address, :class => @address_class
      @doc = @klass.new
      @doc.pets.build(:name => 'Rasmus')
      @doc.save
    end

    should "be true until existing document is saved" do
      address = @doc.pets.first.build_address(:city => 'Holland', :stats => 'MI')
      address.new?.should be_true
      @doc.save
      address.new?.should be_false
    end
  end

  context "#destroyed?" do
    setup do
      @doc = @klass.create(:pets => [@pet_klass.new(:name => 'sparky')])
    end

    should "be false if root document is not destroyed" do
      @doc.should_not be_destroyed
      @doc.pets.first.should_not be_destroyed
    end

    should "be true if root document is destroyed" do
      @doc.destroy
      @doc.should be_destroyed
      @doc.pets.first.should be_destroyed
    end
  end

  context "#persisted?" do
    setup do
      @doc = @klass.new(:name => 'persisted doc', :pets => [@pet_klass.new(:name => 'persisted pet')])
    end

    should "be false if new" do
      @doc.pets.first.should_not be_persisted
    end

    should "be false if destroyed" do
      @doc.save
      @doc.destroy
      @doc.pets.first.should be_destroyed
      @doc.pets.first.should_not be_persisted
    end

    should "be true if not new or destroyed" do
      @doc.save
      @doc.pets.first.should be_persisted
    end
  end

  should "be able to save" do
    person = @klass.create

    pet = @pet_klass.new(:name => 'sparky')
    person.pets << pet
    pet.should be_new
    pet.save
    pet.should_not be_new

    person.reload
    person.pets.first.should == pet
  end

  should "be able to save!" do
    person = @klass.create

    pet = @pet_klass.new(:name => 'sparky')
    person.pets << pet
    pet.should be_new

    person.expects(:save!)
    pet.save!
  end

  should "be able to dynamically add new keys and save" do
    person = @klass.create

    pet = @pet_klass.new(:name => 'sparky', :crazy_key => 'crazy')
    person.pets << pet
    pet.save

    person.reload
    person.pets.first.crazy_key.should == 'crazy'
  end

  should "be able to update_attribute" do
    pet = @pet_klass.new(:name => 'sparky')
    person = @klass.create(:pets => [pet])
    person.reload
    pet = person.pets.first

    pet.update_attribute('name', 'koda').should be_true
    person.reload
    person.pets.first._id.should == pet._id
    person.pets.first.name.should == 'koda'
  end

  should "be able to update_attributes" do
    pet = @pet_klass.new(:name => 'sparky')
    person = @klass.create(:pets => [pet])
    person.reload
    pet = person.pets.first

    pet.update_attributes(:name => 'koda').should be_true
    person.reload
    person.pets.first._id.should == pet._id
    person.pets.first.name.should == 'koda'
  end

  should "be able to update_attributes!" do
    person = @klass.create(:pets => [@pet_klass.new(:name => 'sparky')])
    person.reload
    pet = person.pets.first

    attributes = {:name => 'koda'}
    pet.expects(:attributes=).with(attributes)
    pet.expects(:save!)
    pet.update_attributes!(attributes)
  end

  should "have database instance method that is equal to root document" do
    person = @klass.create(:pets => [@pet_klass.new(:name => 'sparky')])
    person.pets.first.database.should == person.database
  end

  should "have collection instance method that is equal to root document" do
    person = @klass.create(:pets => [@pet_klass.new(:name => 'sparky')])
    person.pets.first.collection.name.should == person.collection.name
  end
end