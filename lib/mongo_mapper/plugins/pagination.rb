# encoding: UTF-8
module MongoMapper
  module Plugins
    module Pagination
      extend ActiveSupport::Concern

      module ClassMethods
        def per_page; 25 end

        def paginate(opts={})
          query.paginate({:per_page => per_page}.merge(opts))
        end
      end
    end
  end
end