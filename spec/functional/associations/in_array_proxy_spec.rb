require 'spec_helper'

describe "InArrayProxy" do
  context "description" do
    before do
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

    after do
      Object.send :remove_const, 'List' if defined?(::List)
      Object.send :remove_const, 'User' if defined?(::User)
    end

    it "should default reader to empty array" do
      User.new.lists.should == []
    end

    it "should allow adding to association like it was an array" do
      user = User.new(:name => 'John')
      user.lists <<     List.new(:name => 'Foo1!')
      user.lists.push   List.new(:name => 'Foo2!')
      user.lists.concat List.new(:name => 'Foo3!')
      user.lists.size.should == 3
    end

    it "should ignore adding duplicate ids" do
      user = User.create(:name => 'John')
      list = List.create(:name => 'Foo')
      user.lists << list
      user.lists << list
      user.lists << list

      user.list_ids.should == [list.id]
      user.lists.count.should == 1
    end

    it "should be able to replace the association" do
      user = User.new(:name => 'John')
      list = List.new(:name => 'Foo')
      user.lists = [list]
      user.save.should be_truthy

      user.reload
      user.list_ids.should == [list.id]
      user.lists.size.should == 1
      user.lists[0].name.should == 'Foo'
    end

    context "create" do
      before do
        @user = User.create(:name => 'John')
        @list = @user.lists.create(:name => 'Foo!')
      end

      it "should add id to key" do
        @user.list_ids.should include(@list.id)
      end

      it "should persist id addition to key in database" do
        @user.reload
        @user.list_ids.should include(@list.id)
      end

      it "should add doc to association" do
        @user.lists.should include(@list)
      end

      it "should save doc" do
        @list.should_not be_new
      end

      it "should reset cache" do
        @user.lists.size.should == 1
        @user.lists.create(:name => 'Moo!')
        @user.lists.size.should == 2
      end
    end

    context "create!" do
      before do
        @user = User.create(:name => 'John')
        @list = @user.lists.create!(:name => 'Foo!')
      end

      it "should add id to key" do
        @user.list_ids.should include(@list.id)
      end

      it "should persist id addition to key in database" do
        @user.reload
        @user.list_ids.should include(@list.id)
      end

      it "should add doc to association" do
        @user.lists.should include(@list)
      end

      it "should save doc" do
        @list.should_not be_new
      end

      it "should raise exception if invalid" do
        expect {
          @user.lists.create!
        }.to raise_error(MongoMapper::DocumentNotValid)
      end

      it "should reset cache" do
        @user.lists.size.should == 1
        @user.lists.create!(:name => 'Moo!')
        @user.lists.size.should == 2
      end
    end

    context "Finding scoped to association" do
      before do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1', :position => 1)
        @list2 = @user.lists.create!(:name => 'Foo 2', :position => 2)
        @list3 = @user2.lists.create!(:name => 'Foo 3', :position => 1)
      end

      context "all" do
        it "should work" do
          @user.lists.all(:order => :position.asc).should == [@list1, @list2]
        end

        it "should work with conditions" do
          @user.lists.all(:name => 'Foo 1').should == [@list1]
        end

        it "should not hit the database if ids key is empty" do
          @user.list_ids = []
          expect(@user.lists).to receive(:query).never
          @user.lists.all.should == []
        end
      end

      context "first" do
        it "should work" do
          @user.lists.first(:order => 'position').should == @list1
        end

        it "should work with conditions" do
          @user.lists.first(:position => 2).should == @list2
        end

        it "should not hit the database if ids key is empty" do
          @user.list_ids = []
          expect(@user.lists).to receive(:query).never
          @user.lists.first.should be_nil
        end
      end

      context "last" do
        it "should work" do
          @user.lists.last(:order => 'position').should == @list2
        end

        it "should work with conditions" do
          @user.lists.last(:position => 2, :order => 'position').should == @list2
        end

        it "should not hit the database if ids key is empty" do
          @user.list_ids = []
          expect(@user.lists).to receive(:query).never
          @user.lists.last.should be_nil
        end
      end

      context "with one id" do
        it "should work for id in association" do
          @user.lists.find(@list1.id).should == @list1
        end

        it "should work with string ids" do
          @user.lists.find(@list1.id.to_s).should == @list1
        end

        it "should not work for id not in association" do
          @user.lists.find(@list3.id).should be_nil
        end

        it "should raise error when using ! and not found" do
          expect {
            @user.lists.find!(@list3.id)
          }.to raise_error(MongoMapper::DocumentNotFound)
        end
      end

      context "with multiple ids" do
        it "should work for ids in association" do
          @user.lists.find(@list1.id, @list2.id).should == [@list1, @list2]
        end

        it "should not work for ids not in association" do
          @user.lists.find(@list1.id, @list2.id, @list3.id).should == [@list1, @list2]
        end
      end

      context "with #paginate" do
        before do
          @lists = @user.lists.paginate(:per_page => 1, :page => 1, :order => 'position')
        end

        it "should return total pages" do
          @lists.total_pages.should == 2
        end

        it "should return total entries" do
          @lists.total_entries.should == 2
        end

        it "should return the subject" do
          @lists.collect(&:name).should == ['Foo 1']
        end

        it "should not hit the database if ids key is empty" do
          @user.list_ids = []
          expect(@user.lists).to receive(:query).never
          @user.lists.paginate(:page => 1).should == []
        end
      end

      context "dynamic finders" do
        it "should work with single key" do
          @user.lists.find_by_name('Foo 1').should == @list1
          @user.lists.find_by_name!('Foo 1').should == @list1
          @user.lists.find_by_name('Foo 3').should be_nil
        end

        it "should work with multiple keys" do
          @user.lists.find_by_name_and_position('Foo 1', 1).should == @list1
          @user.lists.find_by_name_and_position!('Foo 1', 1).should == @list1
          @user.lists.find_by_name_and_position('Foo 3', 1).should be_nil
        end

        it "should raise error when using ! and not found" do
          expect {
            @user.lists.find_by_name!('Foo 3')
          }.to raise_error(MongoMapper::DocumentNotFound)
        end

        context "find_or_create_by" do
          it "should not create document if found" do
            lambda {
              list = @user.lists.find_or_create_by_name('Foo 1')
              list.should == @list1
            }.should_not change { List.count }
          end

          it "should create document if not found" do
            lambda {
              list = @user.lists.find_or_create_by_name('Home')
              @user.lists.should include(list)
            }.should change { List.count }
          end
        end
      end
    end

    context "count" do
      before do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1')
        @list2 = @user.lists.create!(:name => 'Foo 2')
        @list3 = @user2.lists.create!(:name => 'Foo 3')
      end

      it "should return number of ids" do
        @user.lists.count.should == 2
        @user2.lists.count.should == 1
      end

      it "should return correct count when given criteria" do
        @user.lists.count(:name => 'Foo 1').should == 1
        @user2.lists.count(:name => 'Foo 1').should == 0
      end

      it "should not hit the database if ids key is empty" do
        @user.list_ids = []
        expect(@user.lists).to receive(:query).never
        @user.lists.count(:name => 'Foo 1').should == 0
      end
    end

    context "Removing documents" do
      before do
        @user = User.create(:name => 'John')
        @user2 = User.create(:name => 'Brandon')
        @list1 = @user.lists.create!(:name => 'Foo 1', :position => 1)
        @list2 = @user.lists.create!(:name => 'Foo 2', :position => 2)
        @list3 = @user2.lists.create!(:name => 'Foo 3', :position => 1)
      end

      context "destroy_all" do
        it "should work" do
          @user.lists.count.should == 2
          @user.lists.destroy_all
          @user.lists.count.should == 0
        end

        it "should work with conditions" do
          @user.lists.count.should == 2
          @user.lists.destroy_all(:name => 'Foo 1')
          @user.lists.count.should == 1
        end
      end

      context "delete_all" do
        it "should work" do
          @user.lists.count.should == 2
          @user.lists.delete_all
          @user.lists.count.should == 0
        end

        it "should work with conditions" do
          @user.lists.count.should == 2
          @user.lists.delete_all(:name => 'Foo 1')
          @user.lists.count.should == 1
        end
      end

      it "should work with nullify" do
        @user.lists.count.should == 2

        lambda {
          @user.lists.nullify
        }.should_not change { List.count }

        @user.lists.count.should == 0
      end
    end
  end
end