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
        Docs.stats.should == nil
      else
        Docs.stats['count'].should == 0
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
      Docs.stats.count.should == get_stats['count']
    end

    it "should have the correct namespace" do
      Docs.stats.ns.should == get_stats['ns']
    end

    it "should have the correct size" do
      Docs.stats.size.should == get_stats['size']
    end

    it "should have the correct storage size" do
      Docs.stats.storage_size.should == get_stats['storageSize']
    end

    it "should have the correct average object size" do
      Docs.stats.avg_obj_size.should == get_stats['avgObjSize']
    end

    it "should have the correct number of extents" do
      if get_stats['numExtents']
        Docs.stats.num_extents.should == get_stats['numExtents']
      end
    end

    it "should have the correct number of indexes" do
      Docs.stats.nindexes.should == get_stats['nindexes']
    end

    it "should have the correct last extent size" do
      if get_stats['lastExtentSize']
        Docs.stats.last_extent_size.should == get_stats['lastExtentSize']
      end
    end

    it "should have the correct padding factor" do
      if get_stats['paddingFactor']
        Docs.stats.padding_factor.should == get_stats['paddingFactor']
      end
    end

    it "should have the correct user flags" do
      if get_stats['userFlags']
        Docs.stats.user_flags.should == get_stats['userFlags']
      end
    end

    it "should have the correct total index size" do
      Docs.stats.total_index_size.should == get_stats['totalIndexSize']
    end
  end
end
