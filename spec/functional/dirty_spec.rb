require 'spec_helper'

describe "Dirty" do
  before do
    @document = Doc {
      key :phrase, String
      key :paragraph, String, :alias => :para
    }
  end

  context "marking changes" do
    it "should not happen if there are none" do
      doc = @document.new
      doc.phrase_changed?.should be_falsey
      doc.phrase_change.should be_nil
    end

    it "should happen when change happens" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_truthy
      doc.phrase_was.should be_nil
      doc.phrase_change.should == [nil, 'Golly Gee Willikers Batman']
    end

    it "should happen when initializing" do
      doc = @document.new(:phrase => 'Foo')
      doc.changed?.should be_truthy
    end

    it "should clear changes on save" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_truthy
      doc.save
      doc.phrase_changed?.should_not be_truthy
      doc.phrase_change.should be_nil
    end

    it "should clear changes on save!" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_truthy
      doc.save!
      doc.phrase_changed?.should_not be_truthy
      doc.phrase_change.should be_nil
    end

    it "should not happen when loading from database" do
      doc = @document.create(:phrase => 'Foo')
      @document.any_instance.should_receive(:attribute_will_change!).never
      @document.any_instance.should_receive(:attribute_changed?).never
      doc = @document.find(doc.id)
      doc.changed?.should be_falsey
    end

    it "should not happen when reloading from database" do
      doc = @document.create(:phrase => 'Foo')
      doc = @document.find(doc.id)

      doc.changed?.should be_falsey
      doc.phrase = 'Fart'
      doc.changed?.should be_truthy
      doc.reload
      doc.changed?.should be_falsey
    end

    it "should happen if changed after loading from database" do
      doc = @document.create(:phrase => 'Foo')
      doc.reload
      doc.changed?.should be_falsey
      doc.phrase = 'Bar'
      doc.changed?.should be_truthy
    end

    it "should happen with aliased keys" do
      doc = @document.create(:paragraph => 'Wibbly')
      doc.paragraph = "Wobbly"
      doc.changed?.should be_truthy
      doc.paragraph_changed?.should be_truthy
    end
  end

  context "blank new value and type integer" do
    it "should not mark changes" do
      @document.key :age, Integer

      [nil, ''].each do |value|
        doc = @document.new
        doc.age = value
        doc.age_changed?.should be_falsey
        doc.age_change.should be_nil
      end
    end
  end

  context "blank new value and type float" do
    it "should not mark changes" do
      @document.key :amount, Float

      [nil, ''].each do |value|
        doc = @document.new
        doc.amount = value
        doc.amount_changed?.should be_falsey
        doc.amount_change.should be_nil
      end
    end
  end

  context "changed?" do
    it "should be true if key changed" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changed?.should be_truthy
    end

    it "should be false if no keys changed" do
      @document.new.changed?.should be_falsey
    end

    it "should not raise when key name is 'value'" do
      @document.key :value, Integer

      doc = @document.new
      doc.value_changed?.should be_falsey
    end

    it "should be false if the same ObjectId was assigned in String format" do
      @document.key :doc_id, ObjectId

      doc = @document.create!(:doc_id => BSON::ObjectId.new)
      doc.changed?.should be_falsey
      doc.doc_id = doc.doc_id.to_s
      doc.changed?.should be_falsey
    end
  end

  context "changes" do
    it "should be empty hash if no changes" do
      @document.new.changes.should == {}
    end

    it "should be hash of keys with values of changes if there are changes" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changes['phrase'].should == [nil, 'A penny saved is a penny earned.']
    end
  end

  context "changed" do
    it "should be empty array if no changes" do
      @document.new.changed.should == []
    end

    it "should be array of keys that have changed if there are changes" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changed.should == ['phrase']
    end
  end

  context "will_change!" do
    it "should mark changes" do
      doc = @document.create(:phrase => 'Foo')

      doc.phrase << 'bar'
      doc.phrase_changed?.should be_falsey

      doc.phrase_will_change!
      doc.phrase_changed?.should be_truthy
      doc.phrase_change.should == ['Foobar', 'Foobar']

      doc.phrase << '!'
      doc.phrase_changed?.should be_truthy
      doc.phrase_change.should == ['Foobar', 'Foobar!']
    end
  end

  context "changing a foreign key through association" do
    it "should mark changes" do
      project_class = Doc do
        key :name, String
      end

      milestone_class = Doc do
        key :project_id, ObjectId
        key :name, String
      end
      milestone_class.belongs_to :project, :class => project_class

      milestone = milestone_class.create(:name => 'Launch')
      milestone.project = project_class.create(:name => 'Harmony')
      milestone.changed?.should be_truthy
      milestone.changed.should == %w(project_id)
    end
  end

  context "save with an invalid document" do
    it "should not clear changes" do
      validated_class = Doc do
        key :name, String
        key :required, String, :required=>true
      end
      validated_doc = validated_class.new
      validated_doc.name = "I'm a changin"
      validated_doc.save
      validated_doc.changed?.should be_truthy

      validated_doc.required = 1
      validated_doc.save
      validated_doc.changed?.should be_falsey
    end
  end

  context "changing an already changed attribute" do
    it "should preserve the original value" do
      doc = @document.create(:a=>"b")
      doc.a = "c"
      doc.a_change.should == ["b","c"]
      doc.a = "d"
      doc.a_change.should == ["b","d"]
    end
    it "should reset changes when set back to the original value" do
      doc = @document.create(:a=>"b")
      doc.a = "c"
      doc.a = "b"
      doc.changed?.should be_falsey
    end
  end

  context "reset_attribute!" do
    it "should reset the attribute back to the previous value" do
      doc = @document.create(:a=>"b")
      doc.a = "c"
      doc.reset_a!
      doc.changed?.should be_falsey
      doc.a.should == "b"
    end
    it "should reset the attribute back to the original value after several changes" do
      doc = @document.create(:a=>"b")
      doc.a = "c"
      doc.a = "d"
      doc.a = "e"
      doc.reset_a!
      doc.changed?.should be_falsey
      doc.a.should == "b"
    end
  end

  context "previous_changes" do
    it "should reflect previously committed change" do
      doc = @document.create(:a=>"b")
      doc.a = "c"
      changes = doc.changes
      doc.save!
      doc.previous_changes.should == changes
      doc.previous_changes["a"].should == ["b", "c"]
    end

    it "should not include attributes loaded from db" do
      doc = @document.create(:a => "b")
      @document.find(doc.id).previous_changes.should be_blank
    end
  end

  context "Embedded documents" do
    before do
      @edoc = EDoc('Duck') { key :name, String }
      @edoc.plugin MongoMapper::Plugins::Dirty
      @document = Doc('Long') { key :name, String }
      @document.many :ducks, :class=>@edoc
      @doc = @document.new
      @duck = @doc.ducks.build
    end

    it "should track changes" do
      @duck.name = "hi"
      @duck.changed?.should be_truthy
    end

    it "should clear changes when saved" do
      @duck.name = "hi"
      @duck.changed?.should be_truthy
      @duck.save!
      @duck.changed?.should_not be_truthy
    end

    it "should clear changes when the parent is saved" do
      @duck.name = "hi"
      @duck.changed?.should be_truthy
      @doc.save!
      @duck.changed?.should_not be_truthy
    end

    context "with nested embedded documents" do
      before do
        @inner_edoc = EDoc('Dong') {key :name, String}
        @inner_edoc.plugin MongoMapper::Plugins::Dirty
        @edoc.many :dongs, :class=>@inner_edoc
        @dong = @duck.dongs.build
      end

      it "should track changes" do
        @dong.name = "hi"
        @dong.changed?.should be_truthy
      end

      it "should clear changes when the root saves" do
        @dong.name = "hi"
        @dong.changed?.should be_truthy
        @doc.save!
        @dong.changed?.should be_falsey
      end
    end
  end
end
