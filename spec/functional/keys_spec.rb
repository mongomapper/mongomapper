require 'spec_helper'

describe "Keys" do
  context "key segmenting" do
    let(:doc) {
      Doc {
        key :defined
      }
    }

    before do
      doc.collection.insert(:dynamic => "foo")
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
      doc.collection.insert("NotConstant" => "Just data!")
      doc.first.notConstant.should == "Just data!"
    end

    it "should not create accessors for bad keys" do
      doc = Doc {}
      doc.should_not_receive(:create_accessors_for)
      doc.class_eval do
        key :"bad-name", :__dynamic => true
      end
      expect { doc.new.method(:"bad-name") }.to raise_error(NameError)
    end

    it "should create accessors for good keys" do
      doc = Doc {
        key :good_name
      }
      doc.new.good_name.should be_nil
      expect { doc.new.method("good_name") }.to_not raise_error
    end
  end

  it "should handle loading dynamic fields from the database that have bad names" do
    doc = Doc {}
    doc.collection.insert("foo-bar" => "baz-bin")

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
        AliasedKeyModel.collection.find_one.keys.should =~ %w(_id f bar)

        AliasedKeyModel.first.tap do |d|
          d.foo.should == "whee!"
          d.bar.should == "whoo!"
        end
      end

      it "should permit querying via aliases" do
        AliasedKeyModel.where(AliasedKeyModel.abbr(:f) => "whee!").first.foo.should == "whee!"
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
        AliasedKeyModel.collection.find_one["with-hyphens"].should == "foobar"
      end
    end

    context "given a field aliased with :field_name" do
      before { AliasedKeyModel.create(:field_name => "foobar") }
      it "should work" do
        AliasedKeyModel.first.field_name.should == "foobar"
        AliasedKeyModel.collection.find_one["alternate_field_name"].should == "foobar"
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
        owner.associated_documents.should =~ associated_documents

        AssociatedKeyWithAlias.collection.find_one.keys.should =~ %w(_id n aid)
      end

      it "should work with embedded documents" do
        owner = OwnerDocWithKeyAliases.create(:name => "Big Boss")
        owner.other_documents << EmbeddedDocWithAliases.new(:embedded_name => "Underling")
        owner.save

        owner.reload
        owner.other_documents[0].embedded_name.should == "Underling"
        owner.collection.find_one["other_documents"][0]["en"].should == "Underling"
      end
    end
  end
end
