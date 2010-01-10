module MongoMapper
  module Plugins
    module Inspect
      module InstanceMethods
        def inspect
          attributes_as_nice_string = key_names.collect do |name|
            "#{name}: #{self[name].inspect}"
          end.join(", ")
          "#<#{self.class} #{attributes_as_nice_string}>"
        end
      end
    end
  end
end