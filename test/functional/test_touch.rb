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

    context "association" do
      setup do
        @post_class = Doc("Post") { timestamps! }
        @comment_class = Doc("Comment") do
          key :post_id, ObjectId
          key :text, String
          timestamps!
        end

        @post_class.many :comments, :class => @comment_class
        @comment_class.belongs_to :post, :class => @post_class
      end

      should 'not be true by default' do
        @comment_class.associations[:post].touch?.should_not be_true
      end

      context 'touch the parent when true' do
        setup do
          @comment_class.associations[:post].options[:touch] = true
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