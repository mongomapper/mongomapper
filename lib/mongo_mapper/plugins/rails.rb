module MongoMapper
  module Plugins
    module Rails
      module InstanceMethods
        def to_param
          id.to_s
        end
        
        def new_record?
          new?
        end
        
        def read_attribute(name)
          self[name]
        end
        
        def read_attribute_before_typecast(name)
          read_key_before_typecast(name)
        end
        
        def write_attribute(name, value)
          self[name] = value
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