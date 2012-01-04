# encoding: UTF-8
module MongoMapper
  module Plugins
    module Caching
      extend ActiveSupport::Concern

      def cache_key(*suffixes)
        cache_key = case
                      when !persisted?
                        "#{self.class.name}/new"
                      when timestamp = self[:updated_at]
                        "#{self.class.name}/#{id}-#{timestamp.to_s(:number)}"
                      else
                        "#{self.class.name}/#{id}"
                    end
        cache_key += "/#{suffixes.join('/')}" unless suffixes.empty?
        cache_key
      end
    end
  end
end