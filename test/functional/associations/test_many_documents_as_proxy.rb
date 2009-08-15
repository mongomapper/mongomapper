require 'test_helper'
require 'models'

class ManyDocumentsAsProxyTest < Test::Unit::TestCase
  def setup
    clear_all_collections
  end

  should "default reader to empty array" do
    Message.new.votes.should == []
  end

  should "add type and id key to polymorphic class base" do
    Vote.keys.keys.should include('voteable_type')
    Vote.keys.keys.should include('voteable_id')
  end

  should "allow adding to association like it was an array" do
    message = Message.new
    message.votes << Vote.new(:value => true)
    message.votes << Vote.new(:value => false)
    message.votes.concat Vote.new(:value => false)

    message.votes.size.should == 3
  end

  should "be able to replace the association" do
    message = Message.new

    lambda {
      message.votes = [
        Vote.new(:value => true),
        Vote.new(:value => false),
        Vote.new(:value => true)
      ]
    }.should change { Vote.count }.by(3)

    from_db = Message.find(message.id)
    from_db.votes.size.should == 3
    from_db.votes[0].value.should == true
    from_db.votes[1].value.should == false
    from_db.votes[2].value.should == true
  end

  context "build" do
    should "assign foreign key" do
      message = Message.new
      vote = message.votes.build
      vote.voteable_id.should == message.id
    end

    should "assign _type" do
      message = Message.new
      vote = message.votes.build
      vote.voteable_type.should == "Message"
    end

    should "allow assigning attributes" do
      message = Message.new
      vote = message.votes.build(:value => true)
      vote.value.should == true
    end
  end

  context "create" do
    should "assign foreign key" do
      message = Message.new
      vote = message.votes.create
      vote.voteable_id.should == message.id
    end

    should "assign _type" do
      message = Message.new
      vote = message.votes.create
      vote.voteable_type.should == "Message"
    end

    should "save record" do
      message = Message.new
      lambda {
        message.votes.create(:value => false)
      }.should change { Vote.count }
    end

    should "allow passing attributes" do
      message = Message.create
      vote = message.votes.create(:value => true)
      vote.value.should == true
    end
  end

  context "count" do
    should "work scoped to association" do
      message = Message.create
      3.times { message.votes.create(:value => true) }

      other_message = Message.create
      2.times { other_message.votes.create(:value => false) }

      message.votes.count.should == 3
      other_message.votes.count.should == 2
    end

    should "work with conditions" do
      message = Message.create
      message.votes.create(:value => true)
      message.votes.create(:value => false)
      message.votes.create(:value => true)

      message.votes.count(:value => true).should == 2
    end
  end

  context "Finding scoped to association" do
    setup do
      @message = Message.new

      @v1 = Vote.create(:value => true)
      @v2 = Vote.create(:value => false)
      @v3 = Vote.create(:value => true)
      @message.votes = [@v1, @v2]
      @message.save

      @message2 = Message.create(:body => "message #2")
      @v4 = Vote.create(:value => true)
      @v5 = Vote.create(:value => false)
      @v6 = Vote.create(:value => false)
      @message2.votes = [@v4, @v5, @v6]
      @message2.save
    end

    context "with :all" do
      should "work" do
        @message.votes.find(:all).should include(@v1)
        @message.votes.find(:all).should include(@v2)
      end

      should "work with conditions" do
        votes = @message.votes.find(:all, :conditions => {:value => true})
        votes.should == [@v1]
      end

      should "work with order" do
        votes = @message.votes.find(:all, :order => '$natural desc')
        votes.should == [@v2, @v1]
      end
    end

    context "with #all" do
      should "work" do
        @message.votes.all.should == [@v1, @v2]
      end

      should "work with conditions" do
        votes = @message.votes.all(:conditions => {:value => true})
        votes.should == [@v1]
      end

      should "work with order" do
        votes = @message.votes.all(:order => '$natural desc')
        votes.should == [@v2, @v1]
      end
    end

    context "with :first" do
      should "work" do
        lambda {@message.votes.find(:first)}.should_not raise_error
      end

      should "work with conditions" do
        vote = @message.votes.find(:first, :conditions => {:value => false})
        vote.value.should == false
      end
    end

    context "with #first" do
      should "work" do
        @message.votes.first.should == @v1
      end

      should "work with conditions" do
        vote = @message.votes.first(:conditions => {:value => false})
        vote.should == @v2
      end
    end

    context "with :last" do
      should "work" do
        @message.votes.find(:last).should == @v2
      end

      should "work with conditions" do
        message = @message.votes.find(:last, :conditions => {:value => true})
        message.value.should == true
      end
    end

    context "with #last" do
      should "work" do
        @message.votes.last.should == @v2
      end

      should "work with conditions" do
        vote = @message.votes.last(:conditions => {:value => true})
        vote.should == @v1
      end
    end

    context "with one id" do
      should "work for id in association" do
        @message.votes.find(@v2.id).should == @v2
      end

      should "not work for id not in association" do
        lambda {
          @message.votes.find(@v5.id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end

    context "with multiple ids" do
      should "work for ids in association" do
        messages = @message.votes.find(@v1.id, @v2.id)
        messages.should == [@v1, @v2]
      end

      should "not work for ids not in association" do
        lambda {
          @message.votes.find(@v1.id, @v2.id, @v4.id)
        }.should raise_error(MongoMapper::DocumentNotFound)
      end
    end

    context "with #paginate" do
      setup do
        @votes = @message2.votes.paginate(:per_page => 2, :page => 1, :order => '$natural asc')
      end

      should "return total pages" do
        @votes.total_pages.should == 2
      end

      should "return total entries" do
        @votes.total_entries.should == 3
      end

      should "return the subject" do
        @votes.should == [@v4, @v5]
      end
    end
  end
end