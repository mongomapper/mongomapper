require 'test_helper'
require 'models'

class FooMonster; end

class AssociationBaseTest < Test::Unit::TestCase
  include MongoMapper::Plugins::Associations

  should "initialize with type and name" do
    base = ManyAssociation.new(:foos)
    base.name.should == :foos
  end

  should "also allow options when initializing" do
    base = ManyAssociation.new(:foos, :polymorphic => true)
    base.options[:polymorphic].should be_true
  end

  context "klass" do
    should "default to class_name constantized" do
      BelongsToAssociation.new(:foo_monster).klass.should == FooMonster
    end

    should "be the specified class" do
      anonnymous_class = Class.new
      BelongsToAssociation.new(:foo_monster, :class => anonnymous_class).klass.should == anonnymous_class
    end
  end

  context "polymorphic?" do
    should "be true if polymorphic" do
      ManyAssociation.new(:foos, :polymorphic => true).polymorphic?.should be_true
    end

    should "be false if not polymorphic" do
      ManyAssociation.new(:bars).polymorphic?.should be_false
    end
  end

  context "as?" do
    should "be true if one" do
      OneAssociation.new(:foo, :as => :commentable).as?.should be_true
    end

    should "be false if not one" do
      ManyAssociation.new(:foo).as?.should be_false
    end
  end

  context "in_array?" do
    should "be true if one" do
      OneAssociation.new(:foo, :in => :list_ids).in_array?.should be_true
    end

    should "be false if not one" do
      ManyAssociation.new(:foo).in_array?.should be_false
    end
  end

  context "query_options" do
    should "default to empty hash" do
      base = ManyAssociation.new(:foos)
      base.query_options.should == {}
    end

    should "work with order" do
      base = ManyAssociation.new(:foos, :order => 'position')
      base.query_options.should == {:order => 'position'}
    end

    should "correctly parse from options" do
      base = ManyAssociation.new(:foos, :order => 'position', :somekey => 'somevalue')
      base.query_options.should == {:order => 'position', :somekey => 'somevalue'}
    end
  end

  context "type_key_name" do
    should "be association name _ type for belongs_to" do
      BelongsToAssociation.new(:foo).type_key_name.should == 'foo_type'
    end
  end

  context "foreign_key" do
    should "default to assocation name _id for belongs to" do
      base = BelongsToAssociation.new(:foo)
      base.foreign_key.should == 'foo_id'
    end

    should "be overridable with :foreign_key option" do
      base = BelongsToAssociation.new(:foo, :foreign_key => 'foobar_id')
      base.foreign_key.should == 'foobar_id'
    end
  end

  should "have ivar that is association name" do
    BelongsToAssociation.new(:foo).ivar.should == '@_foo'
  end

  context "embeddable?" do
    should "be true if class is embeddable" do
      base = ManyAssociation.new(:medias)
      base.embeddable?.should be_true
    end

    should "be false if class is not embeddable" do
      base = ManyAssociation.new(:statuses)
      base.embeddable?.should be_false

      base = BelongsToAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    should "be BelongsToProxy for belongs_to" do
      base = BelongsToAssociation.new(:project)
      base.proxy_class.should == BelongsToProxy
    end

    should "be BelongsToPolymorphicProxy for polymorphic belongs_to" do
      base = BelongsToAssociation.new(:target, :polymorphic => true)
      base.proxy_class.should == BelongsToPolymorphicProxy
    end

    should "be OneProxy for one" do
      base = OneAssociation.new(:status, :polymorphic => true)
      base.proxy_class.should == OneProxy
    end

    should "be OneEmbeddedProxy for one embedded" do
      base = OneAssociation.new(:media)
      base.proxy_class.should == OneEmbeddedProxy
    end
  end

  context "touch?" do
    should "be true if touch" do
      BelongsToAssociation.new(:car, :touch => true).touch?.should be_true
    end

    should "be false if not touch" do
      BelongsToAssociation.new(:car).touch?.should be_false
    end
  end

end
