require 'test_helper'

class TouchTest < Test::Unit::TestCase
  context "touch" do
    def setup
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
end