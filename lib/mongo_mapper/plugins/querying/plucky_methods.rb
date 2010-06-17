# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      module PluckyMethods
        def where(options={})
          query.where(options)
        end

        def fields(*args)
          query.fields(*args)
        end

        def limit(*args)
          query.limit(*args)
        end

        def skip(*args)
          query.skip(*args)
        end

        def sort(*args)
          query.sort(*args)
        end
      end
    end
  end
end