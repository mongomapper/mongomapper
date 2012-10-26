# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      Methods = Plucky::Methods + [:delete, :delete_all, :destroy, :destroy_all, :find!]

      module Decorator
        include DynamicQuerying::ClassMethods

        def delete(*ids)
          where(:_id => ids.flatten).remove
        end

        def delete_all(options = {})
          where(options).remove
        end

        def destroy(*ids)
          [find!(*ids.flatten.compact.uniq)].flatten.each { |doc| doc.destroy }
        end

        def destroy_all(options={})
          find_each(options) { |document| document.destroy }
        end

        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def find!(*ids)
          raise DocumentNotFound, "Couldn't find without an ID" if ids.size == 0

          find(*ids).tap do |result|
            if result.nil? || ids.size != Array(result).size
              raise DocumentNotFound, "Couldn't find all of the ids (#{ids.join(',')}). Found #{Array(result).size}, but was expecting #{ids.size}"
            end
          end
        end

        private
          def method_missing(method, *args, &block)
            return super unless model.respond_to?(method)
            result = model.send(method, *args, &block)
            if result.is_a?(Plucky::Query)
              merge(result)
            else
              result
            end
          end
      end
    end
  end
end