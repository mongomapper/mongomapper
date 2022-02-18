module MongoMapper
  module Plugins
    module Shardable
      extend ActiveSupport::Concern

      included do
        class_attribute :shard_key_fields
        self.shard_key_fields = []
      end

      def shard_key_filter
        filter = {}
        shard_key_fields.each do |field|
          filter[field] = if new_record?
            send(field)
          else
            changed_attributes.key?(field) ? changed_attributes[field] : send(field)
          end
        end
        filter
      end

      module ClassMethods
        def shard_key(*fields)
          self.shard_key_fields = fields.map(&:to_s).freeze
        end
      end
    end
  end
end
