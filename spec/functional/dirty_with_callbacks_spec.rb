require 'spec_helper'

describe 'DirtyWithCallbacks' do
  it 'should update its changes/previous_changes before after_create/after_update callbacks' do
    history = {}

    document = Doc {
      key :x, String

      after_save {
        history[:after_save] = {
          changes: changes,
          previous_changes: previous_changes,
        }
      }
      after_create {
        history[:after_create] = {
          changes: changes,
          previous_changes: previous_changes,
        }
      }
      after_update {
        history[:after_update] = {
          changes: changes,
          previous_changes: previous_changes,
        }
      }
    }

    d = document.new(x: 'hello')
    d.save

    history.should == {
      after_save: {
        changes: {},
        previous_changes: {'x' => [nil, 'hello']},
      },
      after_create: {
        changes: {},
        previous_changes: {'x' => [nil, 'hello']},
      },
    }
    history.clear

    d.x = 'world'
    d.save!

    history.should == {
      after_save: {
        changes: {},
        previous_changes: {'x' => ['hello', 'world']},
      },
      after_update: {
        changes: {},
        previous_changes: {'x' => ['hello', 'world']},
      },
    }
  end
end
