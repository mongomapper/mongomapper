require 'test_helper'
require 'models'

class ManyPolymorphicProxyTest < Test::Unit::TestCase
  def setup
    Room.collection.remove
    Message.collection.remove
  end
  
  should "default reader to empty array" do
    Room.new.messages.should == []
  end
  
  should "add type key to polymorphic class base" do
    Message.keys.keys.should include('_type')
  end
  
  should "allow adding to assiciation like it was an array" do
    room = Room.new
    room.messages << Enter.new
    room.messages.push Exit.new
    room.messages.concat Exit.new
    room.messages.size.should == 3
  end
  
  should "be able to replace the association" do
    room = Room.create(:name => 'Lounge')
    
    lambda {
      room.messages = [
        Enter.new(:body => 'John entered room', :position => 1),
        Chat.new(:body => 'Heyyyoooo!',         :position => 2),
        Exit.new(:body => 'John exited room',   :position => 3)
      ]
    }.should change { Message.count }.by(3)
    
    room = room.reload
    messages = room.messages.all :order => "position"
    messages.size.should == 3
    messages[0].body.should == 'John entered room'
    messages[1].body.should == 'Heyyyoooo!'
    messages[2].body.should == 'John exited room'
  end
  
  should "correctly store type when using <<, push and concat" do
    room = Room.new
    room.messages <<      Enter.new(:body => 'John entered the room', :position => 1)
    room.messages.push    Exit.new(:body => 'John entered the room', :position => 2)
    room.messages.concat  Chat.new(:body => 'Holla!'             , :position => 3)
    
    room = room.reload
    messages = room.messages.all :order => "position"
    messages[0]._type.should == 'Enter'
    messages[1]._type.should == 'Exit'
    messages[2]._type.should == 'Chat'
  end
  
  context "build" do
    should "assign foreign key" do
      room = Room.create
      message = room.messages.build
      message.room_id.should == room._id
    end
    
    should "assign _type" do
      room = Room.create
      message = room.messages.build
      message._type.should == 'Message'
    end
    
    should "allow assigning attributes" do
      room = Room.create
      message = room.messages.build(:body => 'Foo!')
      message.body.should == 'Foo!'
    end
  end
  
  context "create" do
    should "assign foreign key" do
      room = Room.create
      message = room.messages.create
      message.room_id.should == room._id
    end
    
    should "assign _type" do
      room = Room.create
      message = room.messages.create
      message._type.should == 'Message'
    end
    
    should "save record" do
      room = Room.create
      lambda {
        room.messages.create
      }.should change { Message.count }
    end
    
    should "allow passing attributes" do
      room = Room.create
      message = room.messages.create(:body => 'Foo!')
      message.body.should == 'Foo!'
    end
  end
  
  context "count" do
    should "work scoped to association" do
      room = Room.create
      3.times { room.messages.create }
      
      other_room = Room.create
      2.times { other_room.messages.create }
      
      room.messages.count.should == 3
      other_room.messages.count.should == 2
    end
    
    should "work with conditions" do
      room = Room.create
      room.messages.create(:body => 'Foo')
      room.messages.create(:body => 'Other 1')
      room.messages.create(:body => 'Other 2')
      
      room.messages.count(:body => 'Foo').should == 1
    end
  end
  
  context "Finding scoped to association" do
    setup do
      @lounge = Room.create(:name => 'Lounge')
      @lm1 = Message.create(:body => 'Loungin!', :position => 1)
      @lm2 = Message.create(:body => 'I love loungin!', :position => 2)
      @lounge.messages = [@lm1, @lm2]
      @lounge.save
      
      @hall = Room.create(:name => 'Hall')
      @hm1 = Message.create(:body => 'Do not fall in the hall', :position => 1)
      @hm3 = Message.create(:body => 'Loungin!', :position => 3)
      @hm2 = Message.create(:body => 'Hall the king!', :position => 2)
      @hall.messages = [@hm1, @hm2, @hm3]
      @hall.save
    end
    
    context "dynamic finders" do
      should "work with single key" do
        @lounge.messages.find_by_position(1).should == @lm1
        @hall.messages.find_by_position(2).should == @hm2
      end
      
      should "work with multiple keys" do
        @lounge.messages.find_by_body_and_position('Loungin!', 1).should == @lm1
        @lounge.messages.find_by_body_and_position('Loungin!', 2).should be_nil
      end
      
      should "raise error when using !" do
        lambda {
          @lounge.messages.find_by_position!(222)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
      
      context "find_or_create_by" do
        should "not create document if found" do
          lambda {
            message = @lounge.messages.find_or_create_by_body('Loungin!')
            message.room.should == @lounge
            message.should == @lm1
          }.should_not change { Message.count }
        end

        should "create document if not found" do
          lambda {
            message = @lounge.messages.find_or_create_by_body('Yo dawg!')
            message.room.should == @lounge
            message._type.should == 'Message'
          }.should change { Message.count }.by(1)
        end
      end
    end
    
    context "with #all" do
      should "work" do
        @lounge.messages.all(:order => "position").should == [@lm1, @lm2]
      end
      
      should "work with conditions" do
        messages = @lounge.messages.all(:body => 'Loungin!', :order => "position")
        messages.should == [@lm1]
      end
      
      should "work with order" do
        messages = @lounge.messages.all(:order => 'position desc')
        messages.should == [@lm2, @lm1]
      end
    end
    
    context "with #first" do
      should "work" do
        @lounge.messages.first(:order => "position asc").should == @lm1
      end
      
      should "work with conditions" do
        message = @lounge.messages.first(:body => 'I love loungin!', :order => "position asc")
        message.should == @lm2
      end
    end
    
    context "with #last" do
      should "work" do
        @lounge.messages.last(:order => "position asc").should == @lm2
      end
      
      should "work with conditions" do
        message = @lounge.messages.last(:body => 'Loungin!', :order => "position asc")
        message.should == @lm1
      end
    end
    
    context "with one id" do
      should "work for id in association" do
        @lounge.messages.find(@lm2._id).should == @lm2
      end
      
      should "not work for id not in association" do
        lambda {
          @lounge.messages.find!(@hm2._id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end
    
    context "with query options/criteria" do
      should "work with order on association" do
        @lounge.messages.should == [@lm1, @lm2]
      end
      
      should "allow overriding the order provided to the association" do
        @lounge.messages.all(:order => 'position').should == [@lm1, @lm2]
      end
      
      should "allow using conditions on association" do
        @hall.latest_messages.should == [@hm3, @hm2]
      end
    end
    
    context "with multiple ids" do
      should "work for ids in association" do
        messages = @lounge.messages.find(@lm1._id, @lm2._id)
        messages.should == [@lm1, @lm2]
      end
      
      should "not work for ids not in association" do
        assert_raises(MongoMapper::DocumentNotFound) do
          @lounge.messages.find!(@lm1._id, @lm2._id, @hm2._id)
        end
      end
    end
    
    context "with #paginate" do
      setup do
        @messages = @hall.messages.paginate(:per_page => 2, :page => 1, :order => 'position asc')
      end
      
      should "return total pages" do
        @messages.total_pages.should == 2
      end
      
      should "return total entries" do
        @messages.total_entries.should == 3
      end
      
      should "return the subject" do
        @messages.should == [@hm1, @hm2]
      end
    end
  end
  
  context "extending the association" do
    should "work using a block passed to many" do
      room = Room.new(:name => "Amazing Room")
      messages = room.messages = [
        Enter.new(:body => 'John entered room',  :position => 3),
        Chat.new(:body => 'Heyyyoooo!',          :position => 4),
        Exit.new(:body => 'John exited room',    :position => 5),
        Enter.new(:body => 'Steve entered room', :position => 6),
        Chat.new(:body => 'Anyone there?',       :position => 7),
        Exit.new(:body => 'Steve exited room',   :position => 8)
      ]
      room.save
      room.messages.older.should == messages[3..5]
    end
  
    should "work using many's :extend option" do
      
      room = Room.new(:name => "Amazing Room")
      accounts = room.accounts = [
        Bot.new(:last_logged_in => 3.weeks.ago),
        AccountUser.new(:last_logged_in => nil),
        Bot.new(:last_logged_in => 1.week.ago)
      ]
      room.save
      room.accounts.inactive.should == [accounts[1]]
    end
  end
end
