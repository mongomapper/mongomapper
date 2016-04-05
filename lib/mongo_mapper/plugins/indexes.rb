# encoding: UTF-8
module MongoMapper
  module Plugins
    module Indexes
      extend ActiveSupport::Concern

      module ClassMethods
        def ensure_index(spec, options = {})
          #TODO: should we emulate the mongo 1.x behaviour of caching attempts to create indexes?
          collection.indexes.create_one dealias_options(spec), options
        end

        def create_index(spec, options = {})
          collection.indexes.create_one dealias_options(spec), options
        end

        def drop_index(name)
          collection.indexes.drop_one name
        end

        def drop_indexes
          collection.indexes.drop_all
        end

      private

        def dealias_options(options)
          case options
          when Symbol, String
            {abbr(options) => 1}
          when Hash
            dealias_keys(options)
          when Array
            if options.first.is_a?(Hash)
              options.map {|o| dealias_options(o) }
            elsif options.first.is_a?(Array) # [[:foo, 1], [:bar, 1]]
              options.inject({}) {|acc, tuple| acc.merge(dealias_options(tuple))}
            else
              dealias_keys(Hash[*options])
            end
          else
            options
          end
        end
      end
    end
  end
end