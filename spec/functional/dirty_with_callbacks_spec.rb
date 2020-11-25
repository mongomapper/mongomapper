require 'spec_helper'

describe 'DirtyWithCallbacks' do
  it 'should update its changes/previous_changes before after_create/after_update callbacks' do
    document = Doc {
      key :x, String

      after_create {
        changes.should == {}
        previous_changes.should == {'x' => [nil, 'hello']}
      }
      after_update {
        changes.should == {}
        previous_changes.should == {'x' => ['hello', 'world']}
      }
    }

    d = document.create(x: 'hello')
    d.x = 'world'
    d.save!
  end
end
