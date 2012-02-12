# encoding: UTF-8
module MongoMapper
  module Plugins
    module Inspect
      extend ActiveSupport::Concern

      def inspect(include_nil = false)
        keys = include_nil ? key_names : attributes.keys
        attributes_as_nice_string = keys.sort.collect do |name|
          if self[name].nil?
            "#{name}: #{self.send(:"#{name}").inspect}"
          else
            "#{name}: #{self[name].inspect}"
          end
        end.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end
    end
  end
end