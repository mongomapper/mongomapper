require 'spec_helper'

describe "Keys" do
  it "should not have a disparity between the ivar and accessor" do
    doc = Doc do
      key :foo, String

      def modify_foo
        @foo = :baz
      end

      def get_foo
        @foo
      end
    end

    instance = doc.new(:foo => "bar")
    instance.get_foo.should == instance.foo

    instance.foo = :bing
    instance.get_foo.should == instance.foo

    instance.modify_foo
    instance.get_foo.should == instance.foo
  end

  it "should return the value when set using send with the writer method" do
    doc = Doc do
      key :foo, String
    end

    instance = doc.new(:foo => 'bar')
    instance.send("foo=", 'baz').should == 'baz'
    instance.foo.should == 'baz'
  end

  context "when persisting typecasts" do
    Person = Struct.new(:name) do
      def self.to_mongo(value)
        value.name
      end

      def self.from_mongo(value)
        new(value)
      end
    end

    context "when persisting a typecast Array" do
      typecast_key_model = Doc do
        key :people, Array, :typecast => "Person"
      end

      it "should not mutate the model's state" do
        person = Person.new "Bob"
        doc = typecast_key_model.new(:people => [person])

        doc.save!

        doc.people.should == [person]
      end
    end

    context "when persisting a typecast Set" do
      typecast_key_model = Doc do
        key :people, Set, :typecast => "Person"
      end

      it "should not mutate the model's state" do
        person = Person.new "Bob"

        doc = typecast_key_model.new(:people => Set.new([person]))

        doc.save!

        doc.people.should == Set.new([person])
      end
    end
  end

  it "should not bomb if a key is written before Keys#initialize gets to get called" do
    doc = Class.new do
      include MongoMapper::Document

      def initialize
        self.class.key :something, String
        self.something = :other_thing
        super
      end
    end

    lambda { doc.new }.should_not raise_error
  end

  it "should not bomb if a key is read before Keys#initialize gets to get called" do
    doc = Class.new do
      include MongoMapper::Document

      def initialize
        self.class.key :something, String
        self.something
        super
      end
    end

    lambda { doc.new }.should_not raise_error
  end

  it "should permit for key overrides" do
    doc = Class.new do
      include MongoMapper::Document
      key :class, String, :accessors => :skip
    end

    doc.collection.insert_one('class' => 'String')
    doc.all.first.tap do |d|
      d.class.should == doc
      d["class"].should == "String"
      d.attributes["class"].should == "String"
    end
  end

  context "key segmenting" do
    let(:doc) {
      Doc {
        key :defined
      }
    }

    before do
      doc.collection.insert_one(:dynamic => "foo")
      doc.first
    end

    describe "#dynamic_keys" do
      it "should find dynamic keys" do
        doc.dynamic_keys.keys.should == ["dynamic"]
      end
    end

    describe "#defined_keys" do
      it "should find defined keys" do
        doc.defined_keys.keys.should =~ ["_id", "defined"]
      end
    end
  end

  describe "with invalid names" do
    it "should warn when key names start with an uppercase letter" do
      doc = Doc {}
      Kernel.should_receive(:warn).once.with(/may not start with uppercase letters/)
      doc.class_eval do
        key :NotConstant
      end
    end

    it "should handle keys that start with uppercase letters by translating their first letter to lowercase" do
      doc = Doc {}
      Kernel.stub(:warn)
      doc.class_eval do
        key :NotConstant
      end
      doc.collection.insert_one("NotConstant" => "Just data!")
      doc.first.notConstant.should == "Just data!"
    end

    it "should not create accessors for bad keys" do
      doc = Doc {}
      doc.should_not_receive(:create_accessors_for)
      doc.class_eval do
        key :"bad-name", :__dynamic => true
      end
      lambda { doc.new.method(:"bad-name") }.should raise_error(NameError)
    end

    it "should not create accessors for reserved keys" do
      doc = Doc {}
      doc.should_not_receive(:create_accessors_for)
      doc.class_eval do
        key :"class", :__dynamic => true
      end
      doc.new.class.should == doc
    end

    it "should create accessors for good keys" do
      doc = Doc {
        key :good_name
      }
      doc.new.good_name.should be_nil
      lambda { doc.new.method("good_name") }.should_not raise_error
    end
  end

  it "should handle loading dynamic fields from the database that have bad names" do
    doc = Doc {}
    doc.collection.insert_one("foo-bar" => "baz-bin")

    doc.first["foo-bar"].should == "baz-bin"
  end

  describe "with aliases" do
    AliasedKeyModel = Doc do
      key :foo, :abbr => :f
      key :with_underscores, :alias => "with-hyphens"
      key :field_name, :field_name => "alternate_field_name"
      key :bar
    end

    before { AliasedKeyModel.collection.drop }

    context "standard key operations" do
      before do
        AliasedKeyModel.create(:foo => "whee!", :bar => "whoo!")
      end

      it "should serialize with aliased keys" do
        AliasedKeyModel.collection.find.first.keys.should =~ %w(_id f bar)

        AliasedKeyModel.first.tap do |d|
          d.foo.should == "whee!"
          d.bar.should == "whoo!"
        end
      end

      it "should permit querying via direct field names" do
        AliasedKeyModel.where(AliasedKeyModel.abbr(:foo) => "whee!").first.foo.should == "whee!"
      end

      it "should permit querying via direct field names" do
        AliasedKeyModel.where(:foo => "whee!").criteria_hash.keys.should == ["f"]
        AliasedKeyModel.where(:foo => "whee!").first.foo.should == "whee!"
      end

      it "should permit filtering via aliases" do
        AliasedKeyModel.where(:foo => "whee!").fields(:foo).first.foo.should == "whee!"
      end

      it "should permit dealiasing of atomic operations" do
        m = AliasedKeyModel.first
        m.set(:foo => 1)
        AliasedKeyModel.collection.find.first["f"].should == 1
        AliasedKeyModel.collection.find.first["foo"].should be_nil
      end

      it "should permit dealiasing of update operations" do
        m = AliasedKeyModel.first
        m.update_attributes(:foo => 1)
        AliasedKeyModel.collection.find.first["f"].should == 1
        AliasedKeyModel.collection.find.first["foo"].should be_nil
      end

      it "should not break when unaliasing non-keys" do
        AliasedKeyModel.where(:badkey => "whee!").criteria_hash.keys.should == [:badkey]
      end

      it "should serialize to JSON with full keys" do
        AliasedKeyModel.first.as_json.tap do |json|
          json.should have_key "foo"
          json.should_not have_key "f"
        end
      end
    end

    context "given field which are not valid Ruby method names" do
      before { AliasedKeyModel.create(:with_underscores => "foobar") }
      it "should work" do
        AliasedKeyModel.first.with_underscores.should == "foobar"
        AliasedKeyModel.collection.find.first["with-hyphens"].should == "foobar"
      end
    end

    context "given a field aliased with :field_name" do
      before { AliasedKeyModel.create(:field_name => "foobar") }
      it "should work" do
        AliasedKeyModel.first.field_name.should == "foobar"
        AliasedKeyModel.collection.find.first["alternate_field_name"].should == "foobar"
      end
    end

    context "associations" do
      AssociatedKeyWithAlias = Doc do
        set_collection_name "associated_documents"
        key :name, String, :abbr => :n
        key :association_id, ObjectId, :abbr => :aid
      end

      OwnerDocWithKeyAliases = Doc do
        set_collection_name "owner_documents"
        key :name, String, :abbr => :n
        many :associated_documents, :class_name => "AssociatedKeyWithAlias", :foreign_key => AssociatedKeyWithAlias.abbr(:association_id)
        many :other_documents, :class_name => "EmbeddedDocWithAliases"
      end

      EmbeddedDocWithAliases = EDoc do
        key :embedded_name, String, :abbr => :en
      end

      before do
        AssociatedKeyWithAlias.collection.drop
        OwnerDocWithKeyAliases.collection.drop
      end

      it "should work" do
        owner = OwnerDocWithKeyAliases.create(:name => "Big Boss")

        associated_documents = 3.times.map {|i| AssociatedKeyWithAlias.new(:name => "Associated Record #{i}") }
        owner.associated_documents = associated_documents
        owner.save

        owner.reload
        owner.associated_documents.to_a.should =~ associated_documents.to_a

        AssociatedKeyWithAlias.collection.find.first.keys.should =~ %w(_id n aid)
      end

      it "should work with embedded documents" do
        owner = OwnerDocWithKeyAliases.create(:name => "Big Boss")
        owner.other_documents << EmbeddedDocWithAliases.new(:embedded_name => "Underling")
        owner.save

        owner.reload
        owner.other_documents[0].embedded_name.should == "Underling"
        owner.collection.find.first["other_documents"][0]["en"].should == "Underling"
      end
    end
  end

  describe "removing keys" do
    DocWithRemovedKey = Doc do
      key :something
      validates_uniqueness_of :something
      remove_key :something
    end

    it 'should remove the key' do
      DocWithRemovedKey.keys.should_not have_key "_something"
    end

    it 'should remove validations' do
      DocWithRemovedKey._validate_callbacks.should be_empty
    end
  end

  describe "removing keys in the presence of a validation method" do
    DocWithRemovedValidator = Doc do
      key :something
      validate :something_valid?
      remove_key :something

      def something_valid?; true; end
    end

    it 'should remove the key' do
      DocWithRemovedKey.keys.should_not have_key "_something"
    end
  end

  describe "default with no type" do
    it "should work (regression)" do
      doc = Doc do
        key :a_num, default: 0
      end

      instance = doc.new
      instance.a_num.should == 0

      instance = doc.new(a_num: 10)
      instance.a_num.should == 10
    end
  end

  describe "default value is child of embedded class" do
    class EmbeddedParent
      include MongoMapper::EmbeddedDocument
    end
    class EmbeddedChild < EmbeddedParent
    end
    class DocumentWithEmbeddedAndDefaultValue
      include MongoMapper::Document
      key :my_embedded, EmbeddedParent, default: -> { EmbeddedChild.new }
    end
    it "should work" do
      instance = DocumentWithEmbeddedAndDefaultValue.new
      instance.my_embedded.should be_instance_of(EmbeddedChild)
    end
  end
end
