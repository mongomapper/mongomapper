require 'spec_helper'

describe "Stats" do
  before(:each) do
    class ::Docs
      include MongoMapper::Document
      key   :title, String
      key   :published_at, Time
    end

    Docs.collection.drop
  end

  context "with no documents present" do
    it "should return nil" do
      if Docs.stats == nil
        expect(Docs.stats).to eq(nil)
      else
        expect(Docs.stats['count']).to eq(0)
      end
    end
  end

  context "with documents present" do
    before do
      # Make sure that there is at least one document stored
      Docs.create!
    end

    def get_stats
      MongoMapper.database.command(:collstats => 'docs').documents[0]
    end

    it "should have the correct count" do
      expect(Docs.stats.count).to eq(get_stats['count'])
    end

    it "should have the correct namespace" do
      expect(Docs.stats.ns).to eq(get_stats['ns'])
    end

    it "should have the correct size" do
      expect(Docs.stats.size).to eq(get_stats['size'])
    end

    it "should have the correct storage size" do
      expect(Docs.stats.storage_size).to eq(get_stats['storageSize'])
    end

    it "should have the correct average object size" do
      expect(Docs.stats.avg_obj_size).to eq(get_stats['avgObjSize'])
    end

    it "should have the correct number of extents" do
      if get_stats['numExtents']
        expect(Docs.stats.num_extents).to eq(get_stats['numExtents'])
      end
    end

    it "should have the correct number of indexes" do
      expect(Docs.stats.nindexes).to eq(get_stats['nindexes'])
    end

    it "should have the correct last extent size" do
      if get_stats['lastExtentSize']
        expect(Docs.stats.last_extent_size).to eq(get_stats['lastExtentSize'])
      end
    end

    it "should have the correct padding factor" do
      if get_stats['paddingFactor']
        expect(Docs.stats.padding_factor).to eq(get_stats['paddingFactor'])
      end
    end

    it "should have the correct user flags" do
      if get_stats['userFlags']
        expect(Docs.stats.user_flags).to eq(get_stats['userFlags'])
      end
    end

    it "should have the correct total index size" do
      expect(Docs.stats.total_index_size).to eq(get_stats['totalIndexSize'])
    end
  end
end
