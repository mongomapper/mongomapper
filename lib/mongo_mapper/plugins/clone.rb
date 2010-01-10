module MongoMapper
  module Plugins
    module Clone
      module InstanceMethods
        def clone
          clone_attributes = self.attributes
          clone_attributes.delete("_id")
          self.class.new(clone_attributes)
        end
      end
    end
  end
end