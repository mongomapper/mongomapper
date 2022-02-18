require 'spec_helper'

describe 'Shardable' do
  let(:sharded_model) {
    Doc do
      key :first_name, String
      key :last_name, String
      shard_key :first_name, :last_name
    end
  }

  describe 'shard_key_fields' do
    it 'returns declared field names' do
      sharded_model.shard_key_fields.should == ['first_name', 'last_name']
    end
  end

  describe 'shard_key_filter' do
    context 'new record' do
      let(:document) { sharded_model.new(first_name: 'John', last_name: 'Smith') }

      it 'returns current values' do
        document.shard_key_filter.should == { 'first_name' => 'John', 'last_name' => 'Smith' }
      end
    end

    context 'persisted record' do
      let(:document) { sharded_model.create!(first_name: 'John', last_name: 'Smith') }

      before do
        document.first_name = 'William'
      end

      it 'returns persisted values' do
        document.shard_key_filter.should == { 'first_name' => 'John', 'last_name' => 'Smith' }
      end
    end
  end

  context 'creating new document' do
    let(:document) { sharded_model.new(first_name: 'John', last_name: 'Smith') }

    it 'inserts new document' do
      lambda { document.save! }.should change { sharded_model.count }.by(1)

      persisted = sharded_model.find(document.id)
      persisted.first_name.should == 'John'
      persisted.last_name.should == 'Smith'
    end
  end

  context 'updating persisted document' do
    let(:document) { sharded_model.create!(first_name: 'John', last_name: 'Smith') }

    before do
      document.first_name = 'William'
    end

    it 'updates persisted document' do
      lambda { document.save! }.should_not change { sharded_model.count }

      persisted = sharded_model.find(document.id)
      persisted.first_name.should == 'William'
      persisted.last_name.should == 'Smith'
    end
  end
end
