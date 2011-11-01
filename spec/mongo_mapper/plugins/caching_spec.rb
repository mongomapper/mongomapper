require 'spec_helper'

describe MongoMapper::Plugins::Caching do
  let(:document) { Doc() }

  it "should respond to cache_key" do
    document.new.should respond_to(:cache_key)
  end
end
