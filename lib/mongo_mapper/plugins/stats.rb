# encoding: UTF-8

module MongoMapper
  module Plugins
    module Stats
      extend ActiveSupport::Concern

      module ClassMethods
        def stats
          stats = collection.stats

          Struct.new(*stats.keys.collect { |key| key.underscore.to_sym }).new(*stats.values)
        rescue
          nil
        end
      end
    end
  end
end
