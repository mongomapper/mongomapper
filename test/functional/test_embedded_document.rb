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
  end

  should "correctly instantiate single collection inherited embedded documents" do
    document = Doc('Foo') do
      key :message, Message
    end

    doc1 = document.create(:message => Enter.new)
    doc1.reload.message.class.should be(Enter)
  end

  context "new?" do
    setup do
      @klass.key :foo, @address_class
    end

    should "be new until document is saved" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      address.new?.should == true
    end

    should "not be new after document is saved" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      doc.save
      doc.foo.new?.should == false
    end

    should "not be new when document is read back" do
      address = @address_class.new(:city => 'South Bend', :state => 'IN')
      doc = @klass.new(:foo => address)
      doc.save

      doc = doc.reload
      doc.foo.new?.should == false
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

  should "be able to dynamically add new keys and save" do
    person = @klass.create

    pet = @pet_klass.new(:name => 'sparky', :crazy_key => 'crazy')
    person.pets << pet
    pet.save

    person.reload
    person.pets.first.crazy_key.should == 'crazy'
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
end