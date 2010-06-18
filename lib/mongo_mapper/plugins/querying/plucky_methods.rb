# encoding: UTF-8
require 'forwardable'

module MongoMapper
  module Plugins
    module Querying
      module PluckyMethods
        extend Forwardable
        def_delegators :query,  :where, :fields, :limit, :skip, :sort,
                                :count, :last, :first, :all, :paginate,
                                :find, :find!, :exists?, :exist?, :find_each
      end
    end
  end
end