require 'test_helper'

class ModifierTest < Test::Unit::TestCase
  def setup
    @page_class = Doc do
      key :title,       String
      key :day_count,   Integer, :default => 0
      key :week_count,  Integer, :default => 0
      key :month_count, Integer, :default => 0
      key :tags,        Array
    end
  end

  def assert_page_counts(page, day_count, week_count, month_count)
    page.reload
    page.day_count.should == day_count
    page.week_count.should == week_count
    page.month_count.should == month_count
  end

  def assert_keys_removed(page, *keys)
    keys.each do |key|
      doc = @page_class.collection.find_one({:_id => page.id})
      doc.keys.should_not include(key)
    end
  end

  context "ClassMethods" do
    context "unset" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "work with criteria and keys" do
        @page_class.unset({:title => 'Home'}, :title, :tags)
        assert_keys_removed @page, :title, :tags
        assert_keys_removed @page2, :title, :tags
      end
      
      should "work with ids and keys" do
        @page_class.unset(@page.id, @page2.id, :title, :tags)
        assert_keys_removed @page, :title, :tags
        assert_keys_removed @page2, :title, :tags
      end

      context "additional options (upsert & safe)" do
        should "be able to pass upsert option" do
          new_key_value = DateTime.now.to_s
          @page_class.unset({:title => new_key_value, :tags => %w(foo bar)}, :tags, {:upsert => true})
          @page_class.count(:title => new_key_value).should == 1
          @page_class.first(:title => new_key_value).tags.should == []
        end

        should "be able to pass safe option" do
          @page_class.create(:title => "Better Be Safe than Sorry")

          Mongo::Collection.any_instance.expects(:update).with(
            {:title => "Better Be Safe than Sorry"},
            {'$unset' => {:tags => 1}},
            {:safe => true, :multi => true}
          )
          @page_class.unset({:title => "Better Be Safe than Sorry"}, :tags, {:safe => true})
        end

        should "be able to pass both safe and upsert options" do
          new_key_value = DateTime.now.to_s
          @page_class.unset({:title => new_key_value, :tags => %w(foo bar)}, :tags, {:upsert => true, :safe => true})
          @page_class.count(:title => new_key_value).should == 1
          @page_class.first(:title => new_key_value).tags.should == []
        end
      end
    end
    
    context "increment" do
      setup do
        @page  = @page_class.create(:title => 'Home')
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.increment({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)
          
        assert_page_counts @page, 1, 2, 3
        assert_page_counts @page2, 1, 2, 3
      end
    
      should "work with ids and modifier hash" do
        @page_class.increment(@page.id, @page2.id, :day_count => 1, :week_count => 2, :month_count => 3)
    
        assert_page_counts @page, 1, 2, 3
        assert_page_counts @page2, 1, 2, 3
      end
    end
    
    context "decrement" do
      setup do
        @page = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
        @page2 = @page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3)
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.decrement({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)
    
        assert_page_counts @page, 0, 0, 0
        assert_page_counts @page2, 0, 0, 0
      end
    
      should "work with ids and modifier hash" do
        @page_class.decrement(@page.id, @page2.id, :day_count => 1, :week_count => 2, :month_count => 3)
    
        assert_page_counts @page, 0, 0, 0
        assert_page_counts @page2, 0, 0, 0
      end
    
      should "decrement with positive or negative numbers" do
        @page_class.decrement(@page.id, @page2.id, :day_count => -1, :week_count => 2, :month_count => -3)
    
        assert_page_counts @page, 0, 0, 0
        assert_page_counts @page2, 0, 0, 0
      end
    end
    
    context "set" do
      setup do
        @page  = @page_class.create(:title => 'Home')
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.set({:title => 'Home'}, :title => 'Home Revised')
    
        @page.reload
        @page.title.should == 'Home Revised'
    
        @page2.reload
        @page2.title.should == 'Home Revised'
      end
    
      should "work with ids and modifier hash" do
        @page_class.set(@page.id, @page2.id, :title => 'Home Revised')
    
        @page.reload
        @page.title.should == 'Home Revised'
    
        @page2.reload
        @page2.title.should == 'Home Revised'
      end
    
      should "typecast values before querying" do
        @page_class.key :tags, Set
    
        assert_nothing_raised do
          @page_class.set(@page.id, :tags => ['foo', 'bar'].to_set)
          @page.reload
          @page.tags.should == Set.new(['foo', 'bar'])
        end
      end
    
      should "not typecast keys that are not defined in document" do
        assert_raises(BSON::InvalidDocument) do
          @page_class.set(@page.id, :colors => ['red', 'green'].to_set)
        end
      end
    
      should "set keys that are not defined in document" do
        @page_class.set(@page.id, :colors => %w[red green])
        @page.reload
        @page[:colors].should == %w[red green]
      end

      context "additional options (upsert & safe)" do
        should "be able to pass upsert option" do
          new_key_value = DateTime.now.to_s
          @page_class.set({:title => new_key_value}, {:day_count => 1}, {:upsert => true})
          @page_class.count(:title => new_key_value).should == 1
          @page_class.first(:title => new_key_value).day_count.should == 1
        end

        should "be able to pass safe option" do
          @page_class.create(:title => "Better Be Safe than Sorry")

          Mongo::Collection.any_instance.expects(:update).with(
            {:title => "Better Be Safe than Sorry"},
            {'$set' => {:title => "I like safety."}},
            {:safe => true, :multi => true}
          )
          @page_class.set({:title => "Better Be Safe than Sorry"}, {:title => "I like safety."}, {:safe => true})
        end

        should "be able to pass both safe and upsert options" do
          new_key_value = DateTime.now.to_s
          @page_class.set({:title => new_key_value}, {:day_count => 1}, {:upsert => true, :safe => true})
          @page_class.count(:title => new_key_value).should == 1
          @page_class.first(:title => new_key_value).day_count.should == 1
        end
      end
    end
    
    context "push" do
      setup do
        @page  = @page_class.create(:title => 'Home')
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.push({:title => 'Home'}, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    
      should "work with ids and modifier hash" do
        @page_class.push(@page.id, @page2.id, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    end
    
    context "push_all" do
      setup do
        @page  = @page_class.create(:title => 'Home')
        @page2 = @page_class.create(:title => 'Home')
        @tags = %w(foo bar)
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.push_all({:title => 'Home'}, :tags => @tags)
    
        @page.reload
        @page.tags.should == @tags
    
        @page2.reload
        @page2.tags.should == @tags
      end
    
      should "work with ids and modifier hash" do
        @page_class.push_all(@page.id, @page2.id, :tags => @tags)
    
        @page.reload
        @page.tags.should == @tags
    
        @page2.reload
        @page2.tags.should == @tags
      end
    end
    
    context "pull" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
        @page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar))
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.pull({:title => 'Home'}, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(bar)
    
        @page2.reload
        @page2.tags.should == %w(bar)
      end
    
      should "be able to pull with ids and modifier hash" do
        @page_class.pull(@page.id, @page2.id, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(bar)
    
        @page2.reload
        @page2.tags.should == %w(bar)
      end
    end
    
    context "pull_all" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
        @page2 = @page_class.create(:title => 'Home', :tags => %w(foo bar baz))
      end
    
      should "work with criteria and modifier hashes" do
        @page_class.pull_all({:title => 'Home'}, :tags => %w(foo bar))
    
        @page.reload
        @page.tags.should == %w(baz)
    
        @page2.reload
        @page2.tags.should == %w(baz)
      end
    
      should "work with ids and modifier hash" do
        @page_class.pull_all(@page.id, @page2.id, :tags => %w(foo bar))
    
        @page.reload
        @page.tags.should == %w(baz)
    
        @page2.reload
        @page2.tags.should == %w(baz)
      end
    end
    
    context "add_to_set" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => 'foo')
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "be able to add to set with criteria and modifier hash" do
        @page_class.add_to_set({:title => 'Home'}, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    
      should "be able to add to set with ids and modifier hash" do
        @page_class.add_to_set(@page.id, @page2.id, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    end
    
    context "push_uniq" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => 'foo')
        @page2 = @page_class.create(:title => 'Home')
      end
    
      should "be able to push uniq with criteria and modifier hash" do
        @page_class.push_uniq({:title => 'Home'}, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    
      should "be able to push uniq with ids and modifier hash" do
        @page_class.push_uniq(@page.id, @page2.id, :tags => 'foo')
    
        @page.reload
        @page.tags.should == %w(foo)
    
        @page2.reload
        @page2.tags.should == %w(foo)
      end
    end
    
    context "pop" do
      setup do
        @page  = @page_class.create(:title => 'Home', :tags => %w(foo bar))
      end
    
      should "be able to remove the last element the array" do
        @page_class.pop(@page.id, :tags => 1)
        @page.reload
        @page.tags.should == %w(foo)
      end
    
      should "be able to remove the first element of the array" do
        @page_class.pop(@page.id, :tags => -1)
        @page.reload
        @page.tags.should == %w(bar)
      end
    end
    
    context "additional options (upsert & safe)" do
      should "be able to pass upsert option" do
        new_key_value = DateTime.now.to_s
        @page_class.increment({:title => new_key_value}, {:day_count => 1}, {:upsert => true})
        @page_class.count(:title => new_key_value).should == 1
        @page_class.first(:title => new_key_value).day_count.should == 1
      end
      
      should "be able to pass safe option" do
        @page_class.create(:title => "Better Be Safe than Sorry")
        
        # We are trying to increment a key of type string here which should fail
        assert_raises(Mongo::OperationFailure) do
          @page_class.increment({:title => "Better Be Safe than Sorry"}, {:title => 1}, {:safe => true})
        end
      end
      
      should "be able to pass both safe and upsert options" do
        new_key_value = DateTime.now.to_s
        @page_class.increment({:title => new_key_value}, {:day_count => 1}, {:upsert => true, :safe => true})
        @page_class.count(:title => new_key_value).should == 1
        @page_class.first(:title => new_key_value).day_count.should == 1
      end
    end
  end

  context "instance methods" do
    should "be able to unset with keys" do
      page = @page_class.create(:title => 'Foo', :tags => %w(foo))
      page.unset(:title, :tags)
      assert_keys_removed page, :title, :tags
    end
  
    should "be able to increment with modifier hashes" do
      page = @page_class.create
      page.increment(:day_count => 1, :week_count => 2, :month_count => 3)
  
      assert_page_counts page, 1, 2, 3
    end
  
    should "be able to decrement with modifier hashes" do
      page = @page_class.create(:day_count => 1, :week_count => 2, :month_count => 3)
      page.decrement(:day_count => 1, :week_count => 2, :month_count => 3)
      
      assert_page_counts page, 0, 0, 0
    end
      
    should "always decrement when decrement is called whether number is positive or negative" do
      page = @page_class.create(:day_count => 1, :week_count => 2, :month_count => 3)
      page.decrement(:day_count => -1, :week_count => 2, :month_count => -3)
      
      assert_page_counts page, 0, 0, 0
    end
      
    should "be able to set with modifier hashes" do
      page  = @page_class.create(:title => 'Home')
      page.set(:title => 'Home Revised')
      
      page.reload
      page.title.should == 'Home Revised'
    end
      
    should "be able to push with modifier hashes" do
      page = @page_class.create
      page.push(:tags => 'foo')
      
      page.reload
      page.tags.should == %w(foo)
    end
      
    should "be able to push_all with modifier hashes" do
      page = @page_class.create
      page.push_all(:tags => %w(foo bar))
      
      page.reload
      page.tags.should == %w(foo bar)
    end
      
    should "be able to pull with criteria and modifier hashes" do
      page = @page_class.create(:tags => %w(foo bar))
      page.pull(:tags => 'foo')
      
      page.reload
      page.tags.should == %w(bar)
    end
      
    should "be able to pull_all with criteria and modifier hashes" do
      page = @page_class.create(:tags => %w(foo bar baz))
      page.pull_all(:tags => %w(foo bar))
      
      page.reload
      page.tags.should == %w(baz)
    end
      
    should "be able to add_to_set with criteria and modifier hash" do
      page  = @page_class.create(:tags => 'foo')
      page2 = @page_class.create
      
      page.add_to_set(:tags => 'foo')
      page2.add_to_set(:tags => 'foo')
      
      page.reload
      page.tags.should == %w(foo)
      
      page2.reload
      page2.tags.should == %w(foo)
    end
      
    should "be able to push uniq with criteria and modifier hash" do
      page  = @page_class.create(:tags => 'foo')
      page2 = @page_class.create
      
      page.push_uniq(:tags => 'foo')
      page2.push_uniq(:tags => 'foo')
      
      page.reload
      page.tags.should == %w(foo)
      
      page2.reload
      page2.tags.should == %w(foo)
    end
      
    should "be able to pop with modifier hashes" do
      page = @page_class.create(:tags => %w(foo bar))
      page.pop(:tags => 1)
      
      page.reload
      page.tags.should == %w(foo)
    end
    
    should "be able to pass upsert option" do
      page = @page_class.create(:title => "Upsert Page")
      page.increment({:new_count => 1}, {:upsert => true})
      
      page.reload
      page.new_count.should == 1
    end
    
    should "be able to pass safe option" do
      page = @page_class.create(:title => "Safe Page")
      
      # We are trying to increment a key of type string here which should fail
      assert_raises(Mongo::OperationFailure) do
        page.increment({:title => 1}, {:safe => true})
      end
    end
    
    should "be able to pass upsert and safe options" do
      page = @page_class.create(:title => "Upsert and Safe Page")
      page.increment({:another_count => 1}, {:upsert => true, :safe => true})
      
      page.reload
      page.another_count.should == 1
    end
    
  end
end