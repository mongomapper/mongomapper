require 'spec_helper'

describe 'Shardable' do
  describe 'shard_key_fields' do
    it 'returns declared field names' do
      ShardedModel.shard_key_fields.should == ['first_name', 'last_name']
    end
  end

  describe 'shard_key_filter' do
    context 'new record' do
      let(:document) { ShardedModel.new(first_name: 'John', last_name: 'Smith') }

      it 'returns current values' do
        document.shard_key_filter.should == { 'first_name' => 'John', 'last_name' => 'Smith' }
      end
    end

    context 'persisted record' do
      let(:document) { ShardedModel.create!(first_name: 'John', last_name: 'Smith') }

      before do
        document.first_name = 'William'
      end

      it 'returns persisted values' do
        document.shard_key_filter.should == { 'first_name' => 'John', 'last_name' => 'Smith' }
      end
    end
  end

  context 'creating new document' do
    let(:document) { ShardedModel.new(first_name: 'John', last_name: 'Smith') }

    it 'inserts new document' do
      lambda { document.save! }.should change { ShardedModel.count }.by(1)

      persisted = ShardedModel.find(document.id)
      persisted.first_name.should == 'John'
      persisted.last_name.should == 'Smith'
    end
  end

  context 'updating persisted document' do
    let(:document) { ShardedModel.create!(first_name: 'John', last_name: 'Smith') }

    before do
      document.first_name = 'William'
    end

    it 'updates persisted document' do
      lambda { document.save! }.should_not change { ShardedModel.count }

      persisted = ShardedModel.find(document.id)
      persisted.first_name.should == 'William'
      persisted.last_name.should == 'Smith'
    end
  end
end
