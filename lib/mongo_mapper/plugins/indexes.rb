# encoding: UTF-8
module MongoMapper
  module Plugins
    module Indexes
      extend ActiveSupport::Concern

      module ClassMethods
        def ensure_index(spec, options = {})
          collection.ensure_index dealias_options(spec), options
        end

        def create_index(spec, options = {})
          collection.create_index dealias_options(spec), options
        end

        def drop_index(name)
          collection.drop_index name
        end

        def drop_indexes
          collection.drop_indexes
        end

      private

        def dealias_options(options)
          case options
          when Symbol, String
             abbr(options)
          when Hash
            dealias_keys(options)
          when Array
            options.map {|o| dealias_options(o) }
          else
            options
          end
        end
      end
    end
  end
end