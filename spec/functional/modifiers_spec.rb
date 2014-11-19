require 'spec_helper'

module Modifiers
  describe "Modifiers" do
    let(:page_class_with_compound_key) {
      Doc do
        key :_id,         BSON::OrderedHash, :default => lambda { BSON::OrderedHash['n', 42, 'i', BSON::ObjectId.new] }
        key :title,       String
        key :day_count,   Integer, :default => 0
        key :week_count,  Integer, :default => 0
        key :month_count, Integer, :default => 0
        key :tags,        Array
      end
    }

    let(:page_class_with_standard_key) {
      Doc do
        key :title,       String
        key :day_count,   Integer, :default => 0
        key :week_count,  Integer, :default => 0
        key :month_count, Integer, :default => 0
        key :tags,        Array
      end
    }

    def assert_page_counts(page, day_count, week_count, month_count)
      doc = page.collection.find_one({:_id => page.id})
      doc.should be_present, "Could not find document"
      doc.fetch('day_count').should == day_count
      doc.fetch('week_count').should == week_count
      doc.fetch('month_count').should == month_count
    end

    def assert_keys_removed(page, *keys)
      page.class.collection.find_one({:_id => page.id}).tap do |doc|
        doc.should be_present, "Could not find document"
        (doc.keys & keys).should be_empty, "Expected to not have keys #{keys.inspect}, got #{(keys & doc.keys).inspect}"
      end
    end

    context "ClassMethods" do
      let!(:page_class) { page_class_with_standard_key }
      let!(:page)  { page_class.create(:title => 'Home') }
      let!(:page2) { page_class.create(:title => 'Home') }

      context "unset" do
        let!(:page)  { page_class.create(:title => 'Home', :tags => %w(foo bar)) }

        it "should work with criteria and keys" do
          page_class.unset({:title => 'Home'}, :title, :tags)
          assert_keys_removed page, :title, :tags
          assert_keys_removed page2, :title, :tags
        end

        it "should work with ids and keys" do
          page_class.unset(page.id, page2.id, :title, :tags)
          assert_keys_removed page, :title, :tags
          assert_keys_removed page2, :title, :tags
        end

        context "additional options (upsert & safe)" do
          it "should be able to pass upsert option" do
            new_key_value = DateTime.now.to_s
            page_class.unset({:title => new_key_value, :tags => %w(foo bar)}, :tags, {:upsert => true})
            page_class.count(:title => new_key_value).should == 1
            page_class.first(:title => new_key_value).tags.should == []
          end

          it "should be able to pass safe option" do
            page_class.create(:title => "Better Be Safe than Sorry")

            expect_any_instance_of(Mongo::Collection).to receive(:update).with(
              {:title => "Better Be Safe than Sorry"},
              {'$unset' => {:tags => 1}},
              {:w => 1, :multi => true}
            )
            page_class.unset({:title => "Better Be Safe than Sorry"}, :tags, {:w => 1})
          end

          it "should be able to pass both safe and upsert options" do
            new_key_value = DateTime.now.to_s
            page_class.unset({:title => new_key_value, :tags => %w(foo bar)}, :tags, {:upsert => true, :safe => true})
            page_class.count(:title => new_key_value).should == 1
            page_class.first(:title => new_key_value).tags.should == []
          end
        end
      end

      context "increment" do
        it "should work with criteria and modifier hashes" do
          page_class.increment({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)

          assert_page_counts page, 1, 2, 3
          assert_page_counts page2, 1, 2, 3
        end

        it "should work with ids and modifier hash" do
          page_class.increment(page.id, page2.id, :day_count => 1, :week_count => 2, :month_count => 3)

          assert_page_counts page, 1, 2, 3
          assert_page_counts page2, 1, 2, 3
        end

        it "should work with ids given as strings" do
          page_class.increment(page.id.to_s, page2.id.to_s, :day_count => 1, :week_count => 2, :month_count => 3)

          assert_page_counts page, 1, 2, 3
          assert_page_counts page2, 1, 2, 3
        end
      end

      context "decrement" do
        let!(:page)  { page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3) }
        let!(:page2) { page_class.create(:title => 'Home', :day_count => 1, :week_count => 2, :month_count => 3) }

        it "should work with criteria and modifier hashes" do
          page_class.decrement({:title => 'Home'}, :day_count => 1, :week_count => 2, :month_count => 3)

          assert_page_counts page, 0, 0, 0
          assert_page_counts page2, 0, 0, 0
        end

        it "should work with ids and modifier hash" do
          page_class.decrement(page.id, page2.id, :day_count => 1, :week_count => 2, :month_count => 3)

          assert_page_counts page, 0, 0, 0
          assert_page_counts page2, 0, 0, 0
        end

        it "should decrement with positive or negative numbers" do
          page_class.decrement(page.id, page2.id, :day_count => -1, :week_count => 2, :month_count => -3)

          assert_page_counts page, 0, 0, 0
          assert_page_counts page2, 0, 0, 0
        end

        it "should work with ids given as strings" do
          page_class.decrement(page.id.to_s, page2.id.to_s, :day_count => -1, :week_count => 2, :month_count => -3)

          assert_page_counts page, 0, 0, 0
          assert_page_counts page2, 0, 0, 0
        end
      end

      context "set" do
        it "should work with criteria and modifier hashes" do
          page_class.set({:title => 'Home'}, :title => 'Home Revised')

          page.reload
          page.title.should == 'Home Revised'

          page2.reload
          page2.title.should == 'Home Revised'
        end

        it "should work with ids and modifier hash" do
          page_class.set(page.id, page2.id, :title => 'Home Revised')

          page.reload
          page.title.should == 'Home Revised'

          page2.reload
          page2.title.should == 'Home Revised'
        end

        it "should typecast values before querying" do
          page_class.key :tags, Set

          expect {
            page_class.set(page.id, :tags => ['foo', 'bar'].to_set)
            page.reload
            page.tags.should == Set.new(['foo', 'bar'])
          }.to_not raise_error
        end

        it "should not typecast keys that are not defined in document" do
          expect {
            page_class.set(page.id, :colors => ['red', 'green'].to_set)
          }.to raise_error(BSON::InvalidDocument)
        end

        it "should set keys that are not defined in document" do
          page_class.set(page.id, :colors => %w[red green])
          page.reload
          page[:colors].should == %w[red green]
        end

        context "additional options (upsert & safe)" do
          it "should be able to pass upsert option" do
            new_key_value = DateTime.now.to_s
            page_class.set({:title => new_key_value}, {:day_count => 1}, {:upsert => true})
            page_class.count(:title => new_key_value).should == 1
            page_class.first(:title => new_key_value).day_count.should == 1
          end

          it "should be able to pass safe option" do
            page_class.create(:title => "Better Be Safe than Sorry")

            expect_any_instance_of(Mongo::Collection).to receive(:update).with(
              {:title => "Better Be Safe than Sorry"},
              {'$set' => {:title => "I like safety."}},
              {:w => 1, :multi => true}
            )
            page_class.set({:title => "Better Be Safe than Sorry"}, {:title => "I like safety."}, {:safe => true})
          end

          it "should be able to pass both safe and upsert options" do
            new_key_value = DateTime.now.to_s
            page_class.set({:title => new_key_value}, {:day_count => 1}, {:upsert => true, :safe => true})
            page_class.count(:title => new_key_value).should == 1
            page_class.first(:title => new_key_value).day_count.should == 1
          end
        end
      end

      context "push" do
        it "should work with criteria and modifier hashes" do
          page_class.push({:title => 'Home'}, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end

        it "should work with ids and modifier hash" do
          page_class.push(page.id, page2.id, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end
      end

      context "push_all" do
        let(:tags) { %w(foo bar) }

        it "should work with criteria and modifier hashes" do
          page_class.push_all({:title => 'Home'}, :tags => tags)

          page.reload
          page.tags.should == tags

          page2.reload
          page2.tags.should == tags
        end

        it "should work with ids and modifier hash" do
          page_class.push_all(page.id, page2.id, :tags => tags)

          page.reload
          page.tags.should == tags

          page2.reload
          page2.tags.should == tags
        end
      end

      context "pull" do
        let(:page)  { page_class.create(:title => 'Home', :tags => %w(foo bar)) }
        let(:page2) { page_class.create(:title => 'Home', :tags => %w(foo bar)) }

        it "should work with criteria and modifier hashes" do
          page_class.pull({:title => 'Home'}, :tags => 'foo')

          page.reload
          page.tags.should == %w(bar)

          page2.reload
          page2.tags.should == %w(bar)
        end

        it "should be able to pull with ids and modifier hash" do
          page_class.pull(page.id, page2.id, :tags => 'foo')

          page.reload
          page.tags.should == %w(bar)

          page2.reload
          page2.tags.should == %w(bar)
        end
      end

      context "pull_all" do
        let(:page)  { page_class.create(:title => 'Home', :tags => %w(foo bar baz)) }
        let(:page2) { page_class.create(:title => 'Home', :tags => %w(foo bar baz)) }

        it "should work with criteria and modifier hashes" do
          page_class.pull_all({:title => 'Home'}, :tags => %w(foo bar))

          page.reload
          page.tags.should == %w(baz)

          page2.reload
          page2.tags.should == %w(baz)
        end

        it "should work with ids and modifier hash" do
          page_class.pull_all(page.id, page2.id, :tags => %w(foo bar))

          page.reload
          page.tags.should == %w(baz)

          page2.reload
          page2.tags.should == %w(baz)
        end
      end

      context "add_to_set" do
        let(:page) { page_class.create(:title => 'Home', :tags => 'foo') }

        it "should be able to add to set with criteria and modifier hash" do
          page_class.add_to_set({:title => 'Home'}, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end

        it "should be able to add to set with ids and modifier hash" do
          page_class.add_to_set(page.id, page2.id, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end
      end

      context "push_uniq" do
        let(:page) { page_class.create(:title => 'Home', :tags => 'foo') }

        it "should be able to push uniq with criteria and modifier hash" do
          page_class.push_uniq({:title => 'Home'}, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end

        it "should be able to push uniq with ids and modifier hash" do
          page_class.push_uniq(page.id, page2.id, :tags => 'foo')

          page.reload
          page.tags.should == %w(foo)

          page2.reload
          page2.tags.should == %w(foo)
        end
      end

      context "pop" do
        let(:page) { page_class.create(:title => 'Home', :tags => %w(foo bar)) }

        it "should be able to remove the last element the array" do
          page_class.pop(page.id, :tags => 1)
          page.reload
          page.tags.should == %w(foo)
        end

        it "should be able to remove the first element of the array" do
          page_class.pop(page.id, :tags => -1)
          page.reload
          page.tags.should == %w(bar)
        end
      end

      context "additional options (upsert & safe)" do
        it "should be able to pass upsert option" do
          new_key_value = DateTime.now.to_s
          page_class.increment({:title => new_key_value}, {:day_count => 1}, {:upsert => true})
          page_class.count(:title => new_key_value).should == 1
          page_class.first(:title => new_key_value).day_count.should == 1
        end

        it "should be able to pass safe option" do
          page_class.create(:title => "Better Be Safe than Sorry")

          # We are trying to increment a key of type string here which should fail
          expect {
            page_class.increment({:title => "Better Be Safe than Sorry"}, {:title => 1}, {:safe => true})
          }.to raise_error(Mongo::OperationFailure)
        end

        it "should be able to pass both safe and upsert options" do
          new_key_value = DateTime.now.to_s
          page_class.increment({:title => new_key_value}, {:day_count => 1}, {:upsert => true, :safe => true})
          page_class.count(:title => new_key_value).should == 1
          page_class.first(:title => new_key_value).day_count.should == 1
        end
      end
    end

    context "compound keys" do
      it "should create a document" do
        expect {
          page_class_with_compound_key.create(:title => 'Foo', :tags => %w(foo))
        }.to change { page_class_with_compound_key.count }.by(1)
        doc = page_class_with_compound_key.first
        page_class_with_compound_key.find(doc._id).should == doc
      end
    end

    context "instance methods" do
      {
        :page_class_with_standard_key => "with standard key",
        :page_class_with_compound_key => "with compound key",
      }.each do |klass, description|
        context description do
          let!(:page_class) { send(klass) }

          it "should be able to unset with keys" do
            page = page_class.create(:title => 'Foo', :tags => %w(foo))
            page.unset(:title, :tags)
            assert_keys_removed page, :title, :tags
          end

          it "should be able to increment with modifier hashes" do
            page = page_class.create
            page.increment(:day_count => 1, :week_count => 2, :month_count => 3)

            assert_page_counts page, 1, 2, 3
          end

          it "should be able to decrement with modifier hashes" do
            page = page_class.create(:day_count => 1, :week_count => 2, :month_count => 3)
            page.decrement(:day_count => 1, :week_count => 2, :month_count => 3)

            assert_page_counts page, 0, 0, 0
          end

          it "should always decrement when decrement is called whether number is positive or negative" do
            page = page_class.create(:day_count => 1, :week_count => 2, :month_count => 3)
            page.decrement(:day_count => -1, :week_count => 2, :month_count => -3)
            assert_page_counts page, 0, 0, 0
          end

          it "should be able to set with modifier hashes" do
            page  = page_class.create(:title => 'Home')
            page.set(:title => 'Home Revised')

            page.reload
            page.title.should == 'Home Revised'
          end

          it "should be able to push with modifier hashes" do
            page = page_class.create
            page.push(:tags => 'foo')

            page.reload
            page.tags.should == %w(foo)
          end

          it "should be able to push_all with modifier hashes" do
            page = page_class.create
            page.push_all(:tags => %w(foo bar))

            page.reload
            page.tags.should == %w(foo bar)
          end

          it "should be able to pull with criteria and modifier hashes" do
            page = page_class.create(:tags => %w(foo bar))
            page.pull(:tags => 'foo')

            page.reload
            page.tags.should == %w(bar)
          end

          it "should be able to pull_all with criteria and modifier hashes" do
            page = page_class.create(:tags => %w(foo bar baz))
            page.pull_all(:tags => %w(foo bar))

            page.reload
            page.tags.should == %w(baz)
          end

          it "should be able to add_to_set with criteria and modifier hash" do
            page  = page_class.create(:tags => 'foo')
            page2 = page_class.create

            page.add_to_set(:tags => 'foo')
            page2.add_to_set(:tags => 'foo')

            page.reload
            page.tags.should == %w(foo)

            page2.reload
            page2.tags.should == %w(foo)
          end

          it "should be able to push uniq with criteria and modifier hash" do
            page  = page_class.create(:tags => 'foo')
            page2 = page_class.create

            page.push_uniq(:tags => 'foo')
            page2.push_uniq(:tags => 'foo')

            page.reload
            page.tags.should == %w(foo)

            page2.reload
            page2.tags.should == %w(foo)
          end

          it "should be able to pop with modifier hashes" do
            page = page_class.create(:tags => %w(foo bar))
            page.pop(:tags => 1)

            page.reload
            page.tags.should == %w(foo)
          end

          it "should be able to pass upsert option" do
            page = page_class.create(:title => "Upsert Page")
            page.increment({:new_count => 1}, {:upsert => true})

            page.reload
            page.new_count.should == 1
          end

          it "should be able to pass safe option" do
            page = page_class.create(:title => "Safe Page")

            # We are trying to increment a key of type string here which should fail
            expect {
              page.increment({:title => 1}, {:safe => true})
            }.to raise_error(Mongo::OperationFailure)
          end

          it "should be able to pass upsert and safe options" do
            page = page_class.create(:title => "Upsert and Safe Page")
            page.increment({:another_count => 1}, {:upsert => true, :safe => true})

            page.reload
            page.another_count.should == 1
          end
        end
      end
    end
  end
end