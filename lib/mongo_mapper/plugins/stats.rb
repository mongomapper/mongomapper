# encoding: UTF-8

module MongoMapper
  module Plugins
    module Stats
      extend ActiveSupport::Concern
      module ClassMethods
        ALLOWED_OPTIONS = [:scale].freeze

        def stats(opts={})
          query = { :collstats => collection.name }

          opts.each do |k, v|
            if ALLOWED_OPTIONS.include?(k.to_sym)
              query[k.to_sym] = v
            end
          end

          stats = database.command(query).documents[0]
          Struct.new(*stats.keys.collect { |key| key.underscore.to_sym }).new(*stats.values)
        rescue
          nil
        end
      end
    end
  end
end
