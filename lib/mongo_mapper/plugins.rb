# encoding: UTF-8
module MongoMapper
  module Plugins
    if defined?(ActiveSupport::DescendantsTracker::DescendantsArray)
      DescendantsArray = ::ActiveSupport::DescendantsTracker::DescendantsArray
    else
      DescendantsArray = ::Array
    end

    def self.direct_descendants_hash
      @direct_descendants_hash ||= Hash.new { |h,k| h[k] = DescendantsArray.new }
    end

    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      raise ArgumentError,  "Plugins must extend ActiveSupport::Concern" unless ActiveSupport::Concern === mod
      include mod
      direct_descendants.each {|model| model.send(:include, mod) }
      plugins << mod
    end

    def direct_descendants
      Plugins.direct_descendants_hash[self]
    end

    def included(base = nil)
      direct_descendants << base if base
      super
    end

    def inherited(subclass)
      direct_descendants << subclass
      super
    end
  end
end
