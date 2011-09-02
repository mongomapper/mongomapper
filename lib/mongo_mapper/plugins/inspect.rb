# encoding: UTF-8
module MongoMapper
  module Plugins
    module Inspect
      extend ActiveSupport::Concern

      module InstanceMethods
        def inspect(include_nil = false)
          keys = include_nil ? key_names : attributes.keys
          attributes_as_nice_string = keys.sort.collect do |name|
            "#{name}: #{self[name].inspect}"
          end.join(", ")
          "#<#{self.class} #{attributes_as_nice_string}>"
        end
      end
    end
  end
end