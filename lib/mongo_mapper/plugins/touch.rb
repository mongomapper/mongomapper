module MongoMapper
  module Plugins
    module Touch
      extend ActiveSupport::Concern

      def touch(key = :updated_at) 
        raise ArgumentError, "Invalid key named #{key}" unless self.key_names.include?(key.to_s)
        if self.class.embeddable?
          self.write_attribute(key, Time.now.utc)
          self._parent_document.touch
        else
          self.set(key => Time.now.utc)
        end
        true
      end
    end
  end
end
