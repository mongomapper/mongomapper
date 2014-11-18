require 'spec_helper'

describe "Single collection inheritance (document)" do
  context "without a connection", :without_connection => true do
    it "should attempt to create a connection during inheritance" do
      Mongo::MongoClient.should_not_receive(:new)
      doc = Class.new
      doc.send(:include, MongoMapper::Document)
      expect {
        Class.new(doc)
      }.to_not raise_error
    end

    it "should pick up a connection if one wasn't set" do
      doc = Class.new
      doc.send(:include, MongoMapper::Document)
      klass = Class.new(doc)
      klass.connection.should be_nil
      MongoMapper.connection
      klass.connection.should be_a Mongo::MongoClient
    end
  end

  context "with a connection" do
    before do
      class ::DocParent
        include MongoMapper::Document
        key :name, String
      end
      DocParent.collection.remove

      class ::DocDaughter < ::DocParent; end
      class ::DocSon < ::DocParent; end
      class ::DocGrandSon < ::DocSon; end
      class ::DocGrandGrandSon < ::DocGrandSon; end

      DocSon.many :children, :class_name => 'DocGrandSon'

      @parent = DocParent.new({:name => "Daddy Warbucks"})
      @daughter = DocDaughter.new({:name => "Little Orphan Annie"})
    end

    after do
      Object.send :remove_const, 'DocParent'   if defined?(::DocParent)
      Object.send :remove_const, 'DocDaughter' if defined?(::DocDaughter)
      Object.send :remove_const, 'DocSon'      if defined?(::DocSon)
      Object.send :remove_const, 'DocGrandSon' if defined?(::DocGrandSon)
      Object.send :remove_const, 'DocGrandGrandSon' if defined?(::DocGrandGrandSon)
    end

    it "should automatically add _type key to store class" do
      DocParent.key?(:_type).should be_truthy
    end

    it "should use modifiers properly" do
      DocDaughter.increment({:title => 'Home'}, {:day_count => 1}, :upsert => true)
      DocDaughter.first.should_not be_nil
      DocDaughter.first._type.should == "DocDaughter"
    end

    it "should use the same connection in the subclass" do
      parent_class = Class.new do
        include MongoMapper::Document
        connection Mongo::MongoClient.new
      end

      child_class = Class.new(parent_class) do
        include MongoMapper::Document
      end

      child_class.connection.should == child_class.connection
    end

    it "should use the same database in the subclass" do
      parent_class = Class.new do
        include MongoMapper::Document
        set_database_name 'something'
      end

      child_class = Class.new(parent_class) do
        include MongoMapper::Document
      end

      child_class.database.name.should == 'something'
    end

    it "should use the same collection in the subclass" do
      DocDaughter.collection.name.should == DocParent.collection.name
    end

    context "if the subclass changes its collection" do
      before do
        class ::DocSCIOrphan < ::DocParent
          set_collection_name "foobars"
        end
      end

      after do
        Object.send :remove_const, 'DocSCIOrphan'       if defined?(::DocSCIOrphan)
      end

      it "should negate SCI" do
        DocSCIOrphan.collection.name.should == "foobars"
        DocSCIOrphan.should_not be_single_collection_inherited
      end

      it "should remove the _type key" do
        DocParent.keys.should_not have_key "_type"
        DocSCIOrphan.keys.should_not have_key "_type"
      end

      context "and then is subclassed again" do
        before do
          class ::DocSCIOrphanChild < ::DocSCIOrphan
          end
        end

        after do
          Object.send :remove_const, 'DocSCIOrphanChild'  if defined?(::DocSCIOrphanChild)
        end

        it "should reinstate SCI" do
          DocSCIOrphan.should_not be_single_collection_inherited
          DocSCIOrphanChild.should be_single_collection_inherited
        end

        it "should have the _type key" do
          DocSCIOrphan.keys.should have_key "_type"
          DocSCIOrphanChild.keys.should have_key "_type"
        end
      end
    end

    it "should know single_collection_parent" do
      DocParent.single_collection_parent.should be_nil
      DocDaughter.single_collection_parent.should      == DocParent
      DocSon.single_collection_parent.should           == DocParent
      DocGrandSon.single_collection_parent.should      == DocSon
      DocGrandGrandSon.single_collection_parent.should == DocGrandSon
    end

    it "should know single_collection_root" do
      DocParent.single_collection_root.should        == DocParent
      DocDaughter.single_collection_root.should      == DocParent
      DocSon.single_collection_root.should           == DocParent
      DocGrandSon.single_collection_root.should      == DocParent
      DocGrandGrandSon.single_collection_root.should == DocParent
    end

    context ".single_collection_inherited?" do
      it "should be false if has not inherited" do
        DocParent.should_not be_single_collection_inherited
      end

      it "should be true if inherited" do
        DocDaughter.should be_single_collection_inherited
        DocSon.should be_single_collection_inherited
        DocGrandSon.should be_single_collection_inherited
      end
    end

    it "should set _type on initialize" do
      DocDaughter.new._type.should  == 'DocDaughter'
      DocSon.new._type.should       == 'DocSon'
      DocGrandSon.new._type.should  == 'DocGrandSon'
    end

    it "should set _type based on class and ignore assigned values" do
      DocSon.new(:_type => 'DocDaughter')._type.should == 'DocSon'
    end

    context "loading" do
      it "should be based on _type" do
        @parent.save
        @daughter.save

        collection = DocParent.all
        collection.size.should == 2
        collection.first.should be_kind_of(DocParent)
        collection.first.name.should == "Daddy Warbucks"
        collection.last.should be_kind_of(DocDaughter)
        collection.last.name.should == "Little Orphan Annie"
      end

      it "should gracefully handle when _type cannot be constantized" do
        doc = DocParent.new(:name => 'Nunes')
        doc._type = 'FoobarBaz'
        doc.save

        collection = DocParent.all
        collection.last.should == doc
        collection.last.should be_kind_of(DocParent)
      end
    end

    context "querying" do
      it "should find scoped to class" do
        john = DocSon.create(:name => 'John')
        steve = DocSon.create(:name => 'Steve')
        steph = DocDaughter.create(:name => 'Steph')
        carrie = DocDaughter.create(:name => 'Carrie')
        boris = DocGrandSon.create(:name => 'Boris')

        DocGrandGrandSon.all(:order => 'name').should  == []
        DocGrandSon.all(:order => 'name').should  == [boris]
        DocSon.all(:order => 'name').should       == [boris, john, steve]
        DocDaughter.all(:order => 'name').should  == [carrie, steph]
        DocParent.all(:order => 'name').should    == [boris, carrie, john, steph, steve]

        sigmund = DocGrandGrandSon.create(:name => 'Sigmund')

        DocGrandSon.all(:order => 'name').should  == [boris, sigmund]
        DocSon.all(:order => 'name').should       == [boris, john, sigmund, steve]
        DocParent.all(:order => 'name').should    == [boris, carrie, john, sigmund, steph, steve]
      end

      it "should work with nested hash conditions" do
        john = DocSon.create(:name => 'John')
        steve = DocSon.create(:name => 'Steve')
        DocSon.all(:name => {'$ne' => 'Steve'}).should == [john]
      end

      it "should raise error if not found scoped to class" do
        john = DocSon.create(:name => 'John')
        steph = DocDaughter.create(:name => 'Steph')

        lambda {
          DocSon.find!(steph._id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end

      it "should not raise error for find with parent" do
        john = DocSon.create(:name => 'John')

        DocParent.find!(john._id).should == john
      end

      it "should count scoped to class" do
        john = DocSon.create(:name => 'John')
        steve = DocSon.create(:name => 'Steve')
        steph = DocDaughter.create(:name => 'Steph')
        carrie = DocDaughter.create(:name => 'Carrie')

        DocGrandSon.count.should  == 0
        DocSon.count.should       == 2
        DocDaughter.count.should  == 2
        DocParent.count.should    == 4
      end

      it "should not be able to destroy each other" do
        john = DocSon.create(:name => 'John')
        steph = DocDaughter.create(:name => 'Steph')

        lambda {
          DocSon.destroy(steph._id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end

      it "should not be able to delete each other" do
        john = DocSon.create(:name => 'John')
        steph = DocDaughter.create(:name => 'Steph')

        lambda {
          DocSon.delete(steph._id)
        }.should_not change { DocParent.count }
      end

      it "should be able to destroy using parent" do
        john = DocSon.create(:name => 'John')
        steph = DocDaughter.create(:name => 'Steph')

        lambda {
          DocParent.destroy_all
        }.should change { DocParent.count }.by(-2)
      end

      it "should be able to delete using parent" do
        john = DocSon.create(:name => 'John')
        steph = DocDaughter.create(:name => 'Steph')

        lambda {
          DocParent.delete_all
        }.should change { DocParent.count }.by(-2)
      end
    end

    it "should be able to reload single collection inherited parent class" do
      brian = DocParent.create(:name => 'Brian')
      brian.name = 'B-Dawg'
      brian.reload
      brian.name.should == 'Brian'
    end
  end

  describe "Single collection inheritance (embedded document)" do
    before do
      class ::Grandparent
        include MongoMapper::EmbeddedDocument
        key :grandparent, String
      end

      class ::Parent < ::Grandparent
        include MongoMapper::EmbeddedDocument
        key :parent, String
      end

      class ::Child < ::Parent
        include MongoMapper::EmbeddedDocument
        key :child, String
      end

      class ::OtherChild < ::Parent
        include MongoMapper::EmbeddedDocument
        key :other_child, String
      end
    end

    after do
      Object.send :remove_const, 'Grandparent' if defined?(::Grandparent)
      Object.send :remove_const, 'Parent'      if defined?(::Parent)
      Object.send :remove_const, 'Child'       if defined?(::Child)
      Object.send :remove_const, 'OtherChild'  if defined?(::OtherChild)
    end

    it "should automatically add _type key" do
      Grandparent.key?(:_type).should be_truthy
    end

    context ".single_collection_inherited?" do
      it "should be false if has not inherited" do
        Grandparent.should_not be_single_collection_inherited
      end

      it "should be true if inherited" do
        Parent.should be_single_collection_inherited
        Child.should be_single_collection_inherited
        OtherChild.should be_single_collection_inherited
      end
    end

    it "should set _type on initialize" do
      Parent.new._type.should     == 'Parent'
      Child.new._type.should      == 'Child'
      OtherChild.new._type.should == 'OtherChild'
    end

    it "should set _type based on class and ignore assigned values" do
      Child.new(:_type => 'OtherChild')._type.should == 'Child'
    end
  end

  describe "With polymorphism" do
    before :all do
      class SciPolymorphicPost
        include MongoMapper::Document
        belongs_to :article_parent, :polymorphic => true
      end

      class GalleryItem
        include MongoMapper::Document
        belongs_to :gallery_album
        key :text, Hash
        timestamps!
      end

      class TextGalleryItem < GalleryItem;
        many :sci_polymorphic_posts, :as => :article_parent
      end
    end

    it "should find polymorphic SCI items" do
      item = TextGalleryItem.new()
      p = SciPolymorphicPost.create(:article_parent => item)
      p.article_parent_id.should be_a BSON::ObjectId
      p.article_parent_type.should == "TextGalleryItem"

      p.reload.article_parent.sci_polymorphic_posts.all.should include(p)
    end
  end
end