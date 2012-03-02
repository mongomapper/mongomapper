module MongoMapper
  module Plugins
    module Touch
      extend ActiveSupport::Concern

      def touch(key = :updated_at) 
        raise ArgumentError, "Invalid key named #{key}" unless self.key_names.include?(key.to_s)
        self.set(key => Time.now.utc)
        true
      end
    end
  end
end