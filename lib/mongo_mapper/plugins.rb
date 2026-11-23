# encoding: UTF-8
module MongoMapper
  module Plugins
    # Holds weak references to the classes that include a plugin host
    # (MongoMapper::Document / EmbeddedDocument), so that classes discarded by
    # code reloading (e.g. Rails development mode) can be garbage collected.
    #
    # ActiveSupport::DescendantsTracker::DescendantsArray used to provide this,
    # but it was removed in Rails 7.1 and falling back to a plain Array kept
    # every reloaded model class (and everything it references) alive forever.
    class WeakDescendants
      include Enumerable

      def initialize
        @map = ObjectSpace::WeakMap.new
      end

      def <<(klass)
        # Use the class as the value too: older Rubies cannot hold immediates
        # (e.g. true) in a WeakMap.
        @map[klass] = klass
        self
      end

      def each(&block)
        return to_enum(:each) unless block_given?
        @map.each_value(&block)
        self
      end
    end

    def self.direct_descendants_hash
      @direct_descendants_hash ||= Hash.new { |h,k| h[k] = WeakDescendants.new }
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
      Plugins.direct_descendants_hash[self].to_a
    end

    def included(base = nil)
      Plugins.direct_descendants_hash[self] << base if base
      super
    end

    def inherited(subclass)
      Plugins.direct_descendants_hash[self] << subclass
      super
    end
  end
end
