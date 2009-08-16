require 'test_helper'
require 'models'

class FooMonster; end

class AssociationBaseTest < Test::Unit::TestCase
  include MongoMapper::Associations
  
  should "initialize with type and name" do
    base = Base.new(:many, :foos)
    base.type.should == :many
    base.name.should == :foos
  end
  
  should "also allow options when initializing" do
    base = Base.new(:many, :foos, :polymorphic => true)
    base.options[:polymorphic].should be_true
  end
  
  context "class_name" do
    should "work for belongs_to" do
      Base.new(:belongs_to, :user).class_name.should == 'User'
    end
    
    should "work for many" do
      Base.new(:many, :smart_people).class_name.should == 'SmartPerson'
    end
    
    should "be changeable using class_name option" do
      base = Base.new(:many, :smart_people, :class_name => 'IntelligentPerson')
      base.class_name.should == 'IntelligentPerson'
    end
  end
  
  context "klass" do
    should "be class_name constantized" do
      Base.new(:belongs_to, :foo_monster).klass.should == FooMonster
    end
  end
  
  context "many?" do
    should "be true if many" do
      Base.new(:many, :foos).many?.should be_true
    end
    
    should "be false if not many" do
      Base.new(:belongs_to, :foo).many?.should be_false
    end
  end
  
  context "belongs_to?" do
    should "be true if belongs_to" do
      Base.new(:belongs_to, :foo).belongs_to?.should be_true
    end
    
    should "be false if not belongs_to" do
      Base.new(:many, :foos).belongs_to?.should be_false
    end
  end
  
  context "polymorphic?" do
    should "be true if polymorphic" do
      Base.new(:many, :foos, :polymorphic => true).polymorphic?.should be_true
    end
    
    should "be false if not polymorphic" do
      Base.new(:many, :bars).polymorphic?.should be_false
    end
  end
  
  context "type_key_name" do
    should "be _type for many" do
      Base.new(:many, :foos).type_key_name.should == '_type'
    end
    
    should "be association name _ type for belongs_to" do
      Base.new(:belongs_to, :foo).type_key_name.should == 'foo_type'
    end
  end
  
  context "foreign_key" do
    should "default to assocation_name_id" do
      base = Base.new(:belongs_to, :foo)
      base.foreign_key.should == 'foo_id'
    end
    
    should "be overridable with :foreign_key option" do
      base = Base.new(:belongs_to, :foo, :foreign_key => 'foobar_id')
      base.foreign_key.should == 'foobar_id'
    end
  end
  
  should "have ivar that is association name" do
    Base.new(:belongs_to, :foo).ivar.should == '@_foo'
  end
  
  context "embeddable?" do
    should "be true if class is embeddable" do
      base = Base.new(:many, :medias)
      base.embeddable?.should be_true
    end
    
    should "be false if class is not embeddable" do
      base = Base.new(:many, :statuses)
      base.embeddable?.should be_false
      
      base = Base.new(:belongs_to, :project)
      base.embeddable?.should be_false
    end
  end
  
  context "proxy_class" do
    should "be ManyProxy for many" do      
      base = Base.new(:many, :statuses)
      base.proxy_class.should == ManyProxy
    end
    
    should "be ManyPolymorphicProxy for polymorphic many" do
      base = Base.new(:many, :messages, :polymorphic => true)
      base.proxy_class.should == ManyPolymorphicProxy
    end
    
    should "be ManyEmbeddedProxy for many embedded" do
      base = Base.new(:many, :medias)
      base.proxy_class.should == ManyEmbeddedProxy
    end
    
    should "be ManyEmbeddedPolymorphicProxy for polymorphic many embedded" do
      base = Base.new(:many, :medias, :polymorphic => true)
      base.proxy_class.should == ManyEmbeddedPolymorphicProxy
    end
    
    should "be BelongsToProxy for belongs_to" do
      base = Base.new(:belongs_to, :project)
      base.proxy_class.should == BelongsToProxy
    end
    
    should "be BelongsToPolymorphicProxy for polymorphic belongs_to" do
      base = Base.new(:belongs_to, :target, :polymorphic => true)
      base.proxy_class.should == BelongsToPolymorphicProxy
    end
  end
  
end