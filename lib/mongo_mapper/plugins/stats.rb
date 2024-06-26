# encoding: UTF-8

module MongoMapper
  module Plugins
    module Stats
      extend ActiveSupport::Concern
      module ClassMethods
        def stats(scale: nil)
          query = { :collstats => collection.name }
          query[:scale] = scale if scale

          stats = database.command(query).documents[0]
          Struct.new(*stats.keys.collect { |key| key.underscore.to_sym }).new(*stats.values)
        rescue
          nil
        end
      end
    end
  end
end
