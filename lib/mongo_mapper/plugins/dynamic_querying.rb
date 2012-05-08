# encoding: UTF-8
require 'mongo_mapper/plugins/dynamic_querying/dynamic_finder'

module MongoMapper
  module Plugins
    module DynamicQuerying
      extend ActiveSupport::Concern

      module ClassMethods
        def dynamic_find(finder, args)
          attributes = {}

          finder.attributes.each_with_index do |attr, index|
            attributes[attr] = args[index]
          end

          options = args.extract_options!.merge(attributes)

          if result = send(finder.finder, options)
            result
          else
            if finder.raise?
              raise DocumentNotFound, "Couldn't find Document with #{attributes.inspect} in collection named #{collection.name}"
            end

            if finder.instantiator
              self.send(finder.instantiator, attributes)
            end
          end
        end

        protected
          def method_missing(method, *args, &block)
            finder = DynamicFinder.new(method)

            if finder.found?
              dynamic_find(finder, args)
            else
              super
            end
          end
      end
    end
  end
end