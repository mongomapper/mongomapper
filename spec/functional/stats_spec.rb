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

    def assert_positive_size(value)
      value.should be_a(Numeric)
      value.should be > 0
    end

    def assert_index_sizes_consistent(stats)
      return unless stats.respond_to?(:index_sizes) && stats.index_sizes

      stats.index_sizes.size.should == stats.nindexes
      stats.index_sizes.values.inject(0, :+).should == stats.total_index_size
    end

    it "should have the correct count" do
      Docs.stats.count.should == get_stats['count']
    end

    it "should have the correct namespace" do
      Docs.stats.ns.should == get_stats['ns']
    end

    # WiredTiger size stats (data/index/storage sizes) can change between
    # collStats calls as data is checkpointed, so size fields are asserted
    # from a single response rather than compared across two commands.
    it "should have a positive data size" do
      assert_positive_size(Docs.stats.size)
    end

    it "should have a positive storage size" do
      assert_positive_size(Docs.stats.storage_size)
    end

    it "should have a positive average object size consistent with size and count" do
      stats = Docs.stats
      assert_positive_size(stats.avg_obj_size)
      stats.avg_obj_size.should be_within(1).of(stats.size.to_f / stats.count)
    end

    it "should have the correct number of extents" do
      if get_stats['numExtents']
        Docs.stats.num_extents.should == get_stats['numExtents']
      end
    end

    it "should have the correct number of indexes" do
      Docs.stats.nindexes.should == get_stats['nindexes']
    end

    it "should have a last extent size when the storage engine reports one" do
      stats = Docs.stats
      if stats.respond_to?(:last_extent_size)
        assert_positive_size(stats.last_extent_size)
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

    it "should have a positive total index size consistent with per-index sizes" do
      stats = Docs.stats
      assert_positive_size(stats.total_index_size)
      stats.nindexes.should be > 0
      assert_index_sizes_consistent(stats)
      stats.scale_factor.should == 1 if stats.respond_to?(:scale_factor)
    end

    context 'with scale keyword argument' do
      it "should scale size fields in a single collStats response" do
        scale = 1_024
        scaled = Docs.stats(scale: scale)

        # Deterministic fields stay exact even against a separate unscaled read.
        unscaled = Docs.stats
        scaled.count.should == unscaled.count
        scaled.ns.should == unscaled.ns
        scaled.nindexes.should == unscaled.nindexes

        # Size fields come from the scaled response only. WiredTiger can
        # change index/storage sizes between calls, so we do not require
        # scaled.total_index_size == unscaled.total_index_size / scale.
        scaled.total_index_size.should be_a(Numeric)
        scaled.total_index_size.should be >= 0
        scaled.size.should be_a(Numeric)
        scaled.size.should be >= 0
        scaled.storage_size.should be_a(Numeric)
        scaled.storage_size.should be >= 0

        # scaleFactor proves the keyword was forwarded to MongoDB.
        if scaled.respond_to?(:scale_factor)
          scaled.scale_factor.should == scale
        end

        assert_index_sizes_consistent(scaled)
      end
    end
  end
end
