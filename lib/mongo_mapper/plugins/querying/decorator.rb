# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      Methods = Plucky::Methods + [:find!]

      module Decorator
        include DynamicQuerying::ClassMethods

        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def find!(*ids)
          norm_ids = ids.flatten.compact.uniq
          raise DocumentNotFound, "Couldn't find without an ID" if norm_ids.size == 0
          find(*ids).tap do |result|
            if result.nil? || norm_ids.size != Array(result).size
              raise DocumentNotFound, "Couldn't find all of the ids (#{norm_ids.join(',')}). Found #{Array(result).size}, but was expecting #{norm_ids.size}"
            end
          end
        end

        private
          def method_missing(method, *args, &block)
            return super unless model.respond_to?(method)
            result = model.send(method, *args, &block)
            return super unless result.is_a?(Plucky::Query)
            merge(result)
          end
      end
    end
  end
end