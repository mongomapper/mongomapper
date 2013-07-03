# encoding: UTF-8
# This class exists to make sure that Hash's extensions don't end up giving us unordered hashes.
if RUBY_VERSION < "1.9"
  module MongoMapper
    module Extensions
      module OrderedHash
        def to_mongo(value)
          value
        end

        def from_mongo(value)
          value
        end
      end
    end
  end

  class BSON::OrderedHash
    extend MongoMapper::Extensions::OrderedHash
  end
end