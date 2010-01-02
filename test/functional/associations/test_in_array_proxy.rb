require 'test_helper'

class InArrayProxyTest < Test::Unit::TestCase
  context "description" do
    setup do
      class ::List
        include MongoMapper::Document
        key :name, String, :required => true
      end

      class ::User
        include MongoMapper::Document
        key :name, String, :required => true
        key :list_ids, Array
        many :lists, :in => :list_ids
      end
      User.collection.remove
      List.collection.remove
    end

    teardown do
      Object.send :remove_const, 'List' if defined?(::List)
      Object.send :remove_const, 'User' if defined?(::User)
    end
    
    should "default reader to empty array" do
      User.new.lists.should == []
    end

    should "allow adding to association like it was an array" do
      user = User.new(:name => 'John')
      user.lists <<     List.new(:name => 'Foo1!')
      user.lists.push   List.new(:name => 'Foo2!')
      user.lists.concat List.new(:name => 'Foo3!')
      user.lists.size.should == 3
    end
    
    should "ignore adding duplicate ids" do
      user = User.create(:name => 'John')
      list = List.create(:name => 'Foo')
      user.lists << list
      user.lists << list
      user.lists << list
      
      user.list_ids.should == [list.id]
      user.lists.count.should == 1
    end

    should "be able to replace the association" do
      user = User.new(:name => 'John')
      list = List.new(:name => 'Foo')
      user.lists = [list]
      user.save.should be_true

      user.reload
      user.list_ids.should == [list.id]
      user.lists.size.should == 1
      user.lists[0].name.should == 'Foo'
    end

    context "create" do
      setup do
        @user = User.create(:name => 'John')
        @list = @user.lists.create(:name => 'Foo!')
      end

      should "add id to key" do
        @user.list_ids.should include(@list.id)
      end

      should "persist id addition to key in database" do
        @user.reload
        @user.list_ids.should include(@list.id)
      end

      should "add doc to association" do
        @user.lists.should include(@list)
      end

      should "save doc" do
        @list.should_not be_new
      end
    end

    context "create!" do
      setup do
        @user = User.create(:name => 'John')
        @list = @user.lists.create!(:name => 'Foo!')
      end

      should "add id to key" do
        @user.list_ids.should include(@list.id)
      end

      should "persist id addition to key in database" do
        @user.reload
        @user.list_ids.should include(@list.id)
      end

      should "add doc to association" do
        @user.lists.should include(@list)
      end

      should "save doc" do
        @list.should_not be_new
      end

      should "raise exception if invalid" do
        assert_raises(MongoMapper::DocumentNotValid) do
          @user.lists.create!
        end
      end
    end

    context "Finding scoped to association" do
      setup do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1', :position => 1)
        @list2 = @user.lists.create!(:name => 'Foo 2', :position => 2)
        @list3 = @user2.lists.create!(:name => 'Foo 3', :position => 1)
      end

      context "all" do
        should "work" do
          @user.lists.find(:all, :order => :position.asc).should == [@list1, @list2]
          @user.lists.all(:order => :position.asc).should == [@list1, @list2]
        end

        should "work with conditions" do
          @user.lists.find(:all, :name => 'Foo 1').should == [@list1]
          @user.lists.all(:name => 'Foo 1').should == [@list1]
        end
      end

      context "first" do
        should "work" do
          @user.lists.find(:first, :order => 'position').should == @list1
          @user.lists.first(:order => 'position').should == @list1
        end

        should "work with conditions" do
          @user.lists.find(:first, :position => 2).should == @list2
          @user.lists.first(:position => 2).should == @list2
        end
      end

      context "last" do
        should "work" do
          @user.lists.find(:last, :order => 'position').should == @list2
          @user.lists.last(:order => 'position').should == @list2
        end

        should "work with conditions" do
          @user.lists.find(:last, :position => 2, :order => 'position').should == @list2
          @user.lists.last(:position => 2, :order => 'position').should == @list2
        end
      end

      context "with one id" do
        should "work for id in association" do
          @user.lists.find(@list1.id).should == @list1
        end

        should "not work for id not in association" do
          @user.lists.find(@list3.id).should be_nil
        end

        should "raise error when using ! and not found" do
          assert_raises MongoMapper::DocumentNotFound do
            @user.lists.find!(@list3.id)
          end
        end
      end

      context "with multiple ids" do
        should "work for ids in association" do
          @user.lists.find(@list1.id, @list2.id).should == [@list1, @list2]
        end

        should "not work for ids not in association" do
          @user.lists.find(@list1.id, @list2.id, @list3.id).should == [@list1, @list2]
        end
      end

      context "with #paginate" do
        setup do
          @lists = @user.lists.paginate(:per_page => 1, :page => 1, :order => 'position')
        end

        should "return total pages" do
          @lists.total_pages.should == 2
        end

        should "return total entries" do
          @lists.total_entries.should == 2
        end

        should "return the subject" do
          @lists.collect(&:name).should == ['Foo 1']
        end
      end

      context "dynamic finders" do
        should "work with single key" do
          @user.lists.find_by_name('Foo 1').should == @list1
          @user.lists.find_by_name!('Foo 1').should == @list1
          @user.lists.find_by_name('Foo 3').should be_nil
        end

        should "work with multiple keys" do
          @user.lists.find_by_name_and_position('Foo 1', 1).should == @list1
          @user.lists.find_by_name_and_position!('Foo 1', 1).should == @list1
          @user.lists.find_by_name_and_position('Foo 3', 1).should be_nil
        end

        should "raise error when using ! and not found" do
          assert_raises(MongoMapper::DocumentNotFound) do
            @user.lists.find_by_name!('Foo 3')
          end
        end

        context "find_or_create_by" do
          should "not create document if found" do
            lambda {
              list = @user.lists.find_or_create_by_name('Foo 1')
              list.should == @list1
            }.should_not change { List.count }
          end

          should "create document if not found" do
            lambda {
              list = @user.lists.find_or_create_by_name('Home')
              @user.lists.should include(list)
            }.should change { List.count }
          end
        end
      end
    end

    context "count" do
      setup do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1')
        @list2 = @user.lists.create!(:name => 'Foo 2')
        @list3 = @user2.lists.create!(:name => 'Foo 3')
      end

      should "return number of ids" do
        @user.lists.count.should == 2
        @user2.lists.count.should == 1
      end

      should "return correct count when given criteria" do
        @user.lists.count(:name => 'Foo 1').should == 1
        @user2.lists.count(:name => 'Foo 1').should == 0
      end
    end

    context "Removing documents" do
      setup do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1', :position => 1)
        @list2 = @user.lists.create!(:name => 'Foo 2', :position => 2)
        @list3 = @user2.lists.create!(:name => 'Foo 3', :position => 1)
      end

      context "destroy_all" do
        should "work" do
          @user.lists.count.should == 2
          @user.lists.destroy_all
          @user.lists.count.should == 0
        end

        should "work with conditions" do
          @user.lists.count.should == 2
          @user.lists.destroy_all(:name => 'Foo 1')
          @user.lists.count.should == 1
        end
      end

      context "delete_all" do
        should "work" do
          @user.lists.count.should == 2
          @user.lists.delete_all
          @user.lists.count.should == 0
        end

        should "work with conditions" do
          @user.lists.count.should == 2
          @user.lists.delete_all(:name => 'Foo 1')
          @user.lists.count.should == 1
        end
      end

      should "work with nullify" do
        @user.lists.count.should == 2

        lambda {
          @user.lists.nullify
        }.should_not change { List.count }

        @user.lists.count.should == 0
      end
    end
  end
end