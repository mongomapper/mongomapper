# encoding: UTF-8
module MongoMapper
  module Plugins
    module Timestamps
      extend ActiveSupport::Concern

      module ClassMethods
        def timestamps!
          key :created_at, Time
          key :updated_at, Time
          class_eval { before_save :update_timestamps }
        end
      end

      def update_timestamps
        now = Time.now.utc
        self[:created_at] = now if !persisted? && !created_at?
        self[:updated_at] = now
      end
    end
  end
end