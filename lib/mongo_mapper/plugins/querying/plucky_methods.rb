# encoding: UTF-8
require 'forwardable'

module MongoMapper
  module Plugins
    module Querying
      module PluckyMethods
        extend Forwardable
        def_delegators :query,  :where, :filter,
                                :fields, :ignore, :only,
                                :limit, :paginate, :per_page, :skip, :offset,
                                :sort, :order, :reverse,
                                :count,
                                :distinct,
                                :last, :first, :find_one, :all, :find_each,
                                :find, :find!,
                                :exists?, :exist?
      end
    end
  end
end