# encoding: UTF-8
module MongoMapper
  module Plugins
    module Inspect
      extend ActiveSupport::Concern

      module InstanceMethods
        def inspect(include_super=false)
          key_array = include_super ? key_names : attributes.keys
          attributes_as_nice_string = key_array.sort.collect do |name|
            "#{name}: #{self[name].inspect}"
          end.join(", ")
          "#<#{self.class} #{attributes_as_nice_string}>"
        end
      end
    end
  end
end