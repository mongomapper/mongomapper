# encoding: UTF-8
module MongoMapper
  module Plugins
    module Timestamps
      extend ActiveSupport::Concern

      included do
        class_attribute :record_timestamps
        self.record_timestamps = true
      end

      module ClassMethods
        def timestamps!
          key :created_at, Time
          key :updated_at, Time
          class_eval { before_save :update_timestamps }
        end

        def first(options={})
          super(options.reverse_merge(:order => :created_at))
        end

        def last(options={})
          super(options.reverse_merge(:order => :created_at))
        end
      end

      def update_timestamps
        if self.record_timestamps
          now = Time.now.utc
          self[:created_at] = now if !persisted? && !created_at?
          self[:updated_at] = now
        end
        true
      end
    end
  end
end
