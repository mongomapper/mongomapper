require 'spec_helper'

class FooMonster; end

describe MongoMapper::Plugins::Associations::Base do
  Associations = MongoMapper::Plugins::Associations

  it "should initialize with type and name" do
    base = Associations::ManyAssociation.new(:foos)
    base.name.should == :foos
  end

  it "should also allow options when initializing" do
    base = Associations::ManyAssociation.new(:foos, :polymorphic => true)
    base.options[:polymorphic].should be_true
  end

  context "klass" do
    it "should default to class_name constantized" do
      Associations::BelongsToAssociation.new(:foo_monster).klass.should == FooMonster
    end

    it "should be the specified class" do
      anonnymous_class = Class.new
      Associations::BelongsToAssociation.new(:foo_monster, :class => anonnymous_class).klass.should == anonnymous_class
    end
  end

  context "polymorphic?" do
    it "should be true if polymorphic" do
      Associations::ManyAssociation.new(:foos, :polymorphic => true).polymorphic?.should be_true
    end

    it "should be false if not polymorphic" do
      Associations::ManyAssociation.new(:bars).polymorphic?.should be_false
    end
  end

  context "as?" do
    it "should be true if one" do
      Associations::OneAssociation.new(:foo, :as => :commentable).as?.should be_true
    end

    it "should be false if not one" do
      Associations::ManyAssociation.new(:foo).as?.should be_false
    end
  end

  context "in_array?" do
    it "should be true if one" do
      Associations::OneAssociation.new(:foo, :in => :list_ids).in_array?.should be_true
    end

    it "should be false if not one" do
      Associations::ManyAssociation.new(:foo).in_array?.should be_false
    end
  end

  context "query_options" do
    it "should default to empty hash" do
      base = Associations::ManyAssociation.new(:foos)
      base.query_options.should == {}
    end

    it "should work with order" do
      base = Associations::ManyAssociation.new(:foos, :order => 'position')
      base.query_options.should == {:order => 'position'}
    end

    it "should correctly parse from options" do
      base = Associations::ManyAssociation.new(:foos, :order => 'position', :somekey => 'somevalue')
      base.query_options.should == {:order => 'position', :somekey => 'somevalue'}
    end
  end

  context "type_key_name" do
    it "should be association name _ type for belongs_to" do
      Associations::BelongsToAssociation.new(:foo).type_key_name.should == 'foo_type'
    end
  end

  context "foreign_key" do
    it "should default to assocation name _id for belongs to" do
      base = Associations::BelongsToAssociation.new(:foo)
      base.foreign_key.should == 'foo_id'
    end

    it "should be overridable with :foreign_key option" do
      base = Associations::BelongsToAssociation.new(:foo, :foreign_key => 'foobar_id')
      base.foreign_key.should == 'foobar_id'
    end
  end

  it "should have ivar that is association name" do
    Associations::BelongsToAssociation.new(:foo).ivar.should == '@_foo'
  end

  context "embeddable?" do
    it "should be true if class is embeddable" do
      base = Associations::ManyAssociation.new(:medias)
      base.embeddable?.should be_true
    end

    it "should be false if class is not embeddable" do
      base = Associations::ManyAssociation.new(:statuses)
      base.embeddable?.should be_false

      base = Associations::BelongsToAssociation.new(:project)
      base.embeddable?.should be_false
    end
  end

  context "proxy_class" do
    it "should be BelongsToProxy for belongs_to" do
      base = Associations::BelongsToAssociation.new(:project)
      base.proxy_class.should == Associations::BelongsToProxy
    end

    it "should be BelongsToPolymorphicProxy for polymorphic belongs_to" do
      base = Associations::BelongsToAssociation.new(:target, :polymorphic => true)
      base.proxy_class.should == Associations::BelongsToPolymorphicProxy
    end

    it "should be OneProxy for one" do
      base = Associations::OneAssociation.new(:status, :polymorphic => true)
      base.proxy_class.should == Associations::OneProxy
    end

    it "should be OneEmbeddedProxy for one embedded" do
      base = Associations::OneAssociation.new(:media)
      base.proxy_class.should == Associations::OneEmbeddedProxy
    end
  end

end
