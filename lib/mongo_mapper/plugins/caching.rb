module MongoMapper
  module Plugins
    module Caching
      module InstanceMethods
        def cache_key(suffix=nil)
          cache_key = case
                        when new?
                          "#{self.class.name}/new"
                        when timestamp = self[:updated_at]
                          "#{self.class.name}/#{id}-#{timestamp.to_s(:number)}"
                        else
                          "#{self.class.name}/#{id}"
                      end
          cache_key += "/#{suffix}" unless suffix.nil?
          cache_key
        end
      end
    end
  end
end