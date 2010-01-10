module MongoMapper
  module Plugins
    module Rails
      module InstanceMethods
        def new_record?
          new?
        end
      end
      
      module ClassMethods
        def has_one(*args)
          one(*args)
        end
        
        def has_many(*args)
          many(*args)
        end
        
        def column_names
          keys.keys
        end
        
        def human_name
          self.name.demodulize.titleize
        end
      end
    end
  end
end