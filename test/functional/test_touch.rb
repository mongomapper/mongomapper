require 'test_helper'

class TouchTest < Test::Unit::TestCase
  context "touch" do
    context "document" do
      setup do
        @document = Doc { timestamps! }
      end

      should "update the updated_at timestamp" do
        doc = @document.create
        old_updated_at = doc.updated_at

        Timecop.freeze(Time.now + 1.day) do
          doc.touch
        end

        doc.reload
        doc.updated_at.should_not == old_updated_at      
      end
    end

    context "embedded document" do
      should "update the updated_at timestamp" do
        Doc = Doc("Document") { timestamps!}
        Emdoc = EDoc("EmbeddedDocument") { timestamps! }
        Doc.has_many :emdocs, :class => Emdoc

        doc = Doc.create
        emdoc = Emdoc.new
        doc.emdocs << emdoc
        doc.save

        old_updated_at = emdoc.updated_at
        document_old_updated_at = doc.updated_at

        Timecop.freeze(Time.now + 1.day) do
          emdoc.touch
        end

        doc.reload
        emdoc.updated_at.should_not == old_updated_at
        doc.updated_at.should_not == document_old_updated_at
      end
    end

    context "association" do
      setup do
        @post_class = Doc("Post") do
          key :touched_at, DateTime
          timestamps!
        end
        @comment_class = Doc("Comment") do
          key :post_id, ObjectId
          key :text, String
          timestamps!
        end

        @post_class.many :comments, :class => @comment_class
      end

      should 'not be true by default' do
        @comment_class.belongs_to :post, :class => @post_class
        @comment_class.associations[:post].touch?.should_not be_true
      end

      context 'touch the parent when true' do
        setup do
          @comment_class.belongs_to :post, :class => @post_class, :touch => true
          @post = @post_class.create(:title => 'Hello, world!')
          @comment = @post.comments.build
        end

        should "when the child is created" do
          orig_updated_at = @post.updated_at
          Timecop.freeze(Time.now + 1.day) do
            @comment.save
          end

          @post.reload.updated_at.should_not == orig_updated_at
        end
        
        should "when the child is updated" do
          @comment.save
          old_updated_at = @post.updated_at
          Timecop.freeze(Time.now + 2.day) do
            @comment.update_attributes(:text => "Something")
          end
          @post.reload.updated_at.should_not == old_updated_at
        end
        
        should "when the child is touched" do
          @comment.save
          old_updated_at = @post.updated_at
          Timecop.freeze(Time.now + 3.day) do
            @comment.touch
          end
          @post.reload.updated_at.should_not == old_updated_at
        end
      end

      context "when set to a symbol that is a key of parent" do
        should "set that key on touch events" do
          @comment_class.belongs_to :post, :class => @post_class, :touch => :touched_at
          post = @post_class.create(:title => 'Hello, world!')
          post.touched_at.should be_nil

          comment = post.comments.build
          comment.save
          post.reload.touched_at.should_not be_nil
        end
      end

      should 'not touch the parent when false' do
        post = @post_class.create(:title => 'Hello, world!')
        comment = post.comments.build
        Timecop.freeze(Time.now + 1.day) do
          comment.save
        end
      
        post.reload.updated_at.should == post.created_at
      end
    end
  end
end