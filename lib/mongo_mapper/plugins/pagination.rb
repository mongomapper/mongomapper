module MongoMapper
  module Plugins
    module Pagination
      module ClassMethods
        def per_page
          25
        end

        def paginate(options)
          per_page      = options.delete(:per_page) || self.per_page
          page          = options.delete(:page)
          total_entries = count(options)
          pagination    = Pagination::Proxy.new(total_entries, page, per_page)

          options.update(:limit => pagination.limit, :skip => pagination.skip)
          pagination.subject = find_many(options)
          pagination
        end
      end
    end
  end
end

require 'mongo_mapper/plugins/pagination/proxy'