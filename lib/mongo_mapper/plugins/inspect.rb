# encoding: UTF-8
module MongoMapper
  module Plugins
    module Inspect
      extend ActiveSupport::Concern

      def inspect(include_nil = false)
        keys = include_nil ? key_names : attributes.keys
        attributes_as_nice_string = keys.sort.collect do |name|
          raw_value = self.send(:"#{name}").inspect
          filtered_value = MongoMapper::Utils.filter_param(name, raw_value)
          "#{name}: #{filtered_value}"
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end
    end
  end
end
