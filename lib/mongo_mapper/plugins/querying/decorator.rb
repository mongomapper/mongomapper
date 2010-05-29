# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      module Decorator
        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def all(opts={})
          super.map { |doc| model.load(doc) }
        end

        def first(opts={})
          model.load(super)
        end

        def last(opts={})
          model.load(super)
        end
      end
    end
  end
end