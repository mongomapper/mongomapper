require 'test_helper'

class SingleCollectionInheritanceTest < Test::Unit::TestCase
  context "Single collection inheritance" do
    setup do
      class ::DocParent
        include MongoMapper::Document
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

    should "automatically add _type key to store class" do
      DocParent.keys.should include(:_type)
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

    should "set type from class and ignore _type in attributes" do
      doc = DocSon.create(:_type => 'DocDaughter', :name => 'John')
      DocParent.first.should be_instance_of(DocSon)
    end

    should "be able to reload parent inherited class" do
      brian = DocParent.create(:name => 'Brian')
      brian.name = 'B-Dawg'
      brian.reload
      brian.name.should == 'Brian'
    end
  end
end