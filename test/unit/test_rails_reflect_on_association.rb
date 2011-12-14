require 'test_helper'

module ReflectOnAssociationTestModels
  class Tree
    include MongoMapper::Document
    many :birds, :class_name => "ReflectOnAssociationTestModels::Bird"
  end

  class Bird
    include MongoMapper::Document
    belongs_to :tree, :class_name => "ReflectOnAssociationTestModels::Tree"
  end

  class Book
    include MongoMapper::Document
    many :authors, :class_name => "ReflectOnAssociationTestModels::Author", :in => :author_ids
  end

  class Author
    include MongoMapper::Document
  end

  class Employee
    include MongoMapper::Document
    one :desk, :class_name => "ReflectOnAssociationTestModels::Desk"
  end

  class Desk
    include MongoMapper::Document
    belongs_to :employee, :class_name => "ReflectOnAssociationTestModels::Employee"
  end

  class Order
    include MongoMapper::Document
    many :line_items, :class_name => "ReflectOnAssociationTestModels::LineItem"
  end

  class LineItem
    include MongoMapper::EmbeddedDocument
  end

  class Body
    include MongoMapper::Document
    one :heart, :class_name => "ReflectOnAssociationTestModels::Heart"
  end

  class Heart
    include MongoMapper::EmbeddedDocument
  end
end

class ReflectOnAssociationTest < Test::Unit::TestCase
  context "one-to-many association" do
    should "return :has_many association for Tree#birds" do
      association = ReflectOnAssociationTestModels::Tree.reflect_on_association(:birds)
      association.klass.should == ReflectOnAssociationTestModels::Bird
      association.macro.should == :has_many
      association.name.should == :birds
      association.options.should == {}
    end

    should "return :belongs_to association for Bird#tree" do
      association = ReflectOnAssociationTestModels::Bird.reflect_on_association(:tree)
      association.klass.should == ReflectOnAssociationTestModels::Tree
      association.macro.should == :belongs_to
      association.name.should == :tree
      association.options.should == {}
    end
  end

  context "many-to-many association" do
    should "return :has_many association for Book#authors" do
      association = ReflectOnAssociationTestModels::Book.reflect_on_association(:authors)
      association.klass.should == ReflectOnAssociationTestModels::Author
      association.macro.should == :has_many
      association.name.should == :authors
      association.options.should == {}
    end
  end

  context "one-to-one association" do
    should "return :has_one association for Employee#desk" do
      association = ReflectOnAssociationTestModels::Employee.reflect_on_association(:desk)
      association.klass.should == ReflectOnAssociationTestModels::Desk
      association.macro.should == :has_one
      association.name.should == :desk
      association.options.should == {}
    end

    should "return :belongs_to association for Desk#employee" do
      association = ReflectOnAssociationTestModels::Desk.reflect_on_association(:employee)
      association.klass.should == ReflectOnAssociationTestModels::Employee
      association.macro.should == :belongs_to
      association.name.should == :employee
      association.options.should == {}
    end
  end

  context "embeds one" do
    should "return :has_one association for Body#heart" do
      association = ReflectOnAssociationTestModels::Body.reflect_on_association(:heart)
      association.klass.should == ReflectOnAssociationTestModels::Heart
      association.macro.should == :has_one
      association.name.should == :heart
      association.options.should == {}
    end
  end

  context "embeds many" do
    should "return :has_many association for Order#line_items" do
      association = ReflectOnAssociationTestModels::Order.reflect_on_association(:line_items)
      association.klass.should == ReflectOnAssociationTestModels::LineItem
      association.macro.should == :has_many
      association.name.should == :line_items
      association.options.should == {}
    end
  end
end