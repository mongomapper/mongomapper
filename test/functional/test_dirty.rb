require 'test_helper'

class DirtyTest < Test::Unit::TestCase
  def setup
    @document = Doc { key :phrase, String }
  end

  context "marking changes" do
    should "not happen if there are none" do
      doc = @document.new
      doc.phrase_changed?.should be_false
      doc.phrase_change.should be_nil
    end

    should "happen when change happens" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_true
      doc.phrase_was.should be_nil
      doc.phrase_change.should == [nil, 'Golly Gee Willikers Batman']
    end

    should "happen when initializing" do
      doc = @document.new(:phrase => 'Foo')
      doc.changed?.should be_true
    end

    should "clear changes on save" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_true
      doc.save
      doc.phrase_changed?.should_not be_true
      doc.phrase_change.should be_nil
    end

    should "clear changes on save!" do
      doc = @document.new
      doc.phrase = 'Golly Gee Willikers Batman'
      doc.phrase_changed?.should be_true
      doc.save!
      doc.phrase_changed?.should_not be_true
      doc.phrase_change.should be_nil
    end

    should "not happen when loading from database" do
      doc = @document.create(:phrase => 'Foo')
      doc = @document.find(doc.id)
      
      doc.changed?.should be_false
      doc.phrase = 'Fart'
      doc.changed?.should be_true
      doc.reload
      doc.changed?.should be_false
    end

    should "happen if changed after loading from database" do
      doc = @document.create(:phrase => 'Foo')
      doc.reload
      doc.changed?.should be_false
      doc.phrase = 'Bar'
      doc.changed?.should be_true
    end
  end

  context "blank new value and type integer" do
    should "not mark changes" do
      @document.key :age, Integer

      [nil, ''].each do |value|
        doc = @document.new
        doc.age = value
        doc.age_changed?.should be_false
        doc.age_change.should be_nil
      end
    end
  end
  
  context "blank new value and type float" do
    should "not mark changes" do
      @document.key :amount, Float

      [nil, ''].each do |value|
        doc = @document.new
        doc.amount = value
        doc.amount_changed?.should be_false
        doc.amount_change.should be_nil
      end
    end
  end  
  
  context "changed?" do
    should "be true if key changed" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changed?.should be_true
    end
    
    should "be false if no keys changed" do
      @document.new.changed?.should be_false
    end
  end
  
  context "changes" do
    should "be empty hash if no changes" do
      @document.new.changes.should == {}
    end
    
    should "be hash of keys with values of changes if there are changes" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changes['phrase'].should == [nil, 'A penny saved is a penny earned.']
    end
  end
  
  context "changed" do
    should "be empty array if no changes" do
      @document.new.changed.should == []
    end
    
    should "be array of keys that have changed if there are changes" do
      doc = @document.new
      doc.phrase = 'A penny saved is a penny earned.'
      doc.changed.should == ['phrase']
    end
  end
  
  context "will_change!" do
    should "mark changes" do
      doc = @document.create(:phrase => 'Foo')
      
      doc.phrase << 'bar'
      doc.phrase_changed?.should be_false
      
      doc.phrase_will_change!
      doc.phrase_changed?.should be_true
      doc.phrase_change.should == ['Foobar', 'Foobar']
      
      doc.phrase << '!'
      doc.phrase_changed?.should be_true
      doc.phrase_change.should == ['Foobar', 'Foobar!']
    end
  end
  
  context "changing a foreign key through association" do
    should "mark changes" do
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
      milestone.changed?.should be_true
      milestone.changed.should == %w(project_id)
    end
  end
end