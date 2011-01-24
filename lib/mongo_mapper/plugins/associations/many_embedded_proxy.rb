# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyEmbeddedProxy < EmbeddedCollection
        def replace(values)
          @_values = (values || []).map do |v|
            v.respond_to?(:attributes) ? v.attributes : v
          end
          reset
        end

        private
          def find_target
            (@_values || []).map do |attrs|
              klass.load(attrs).tap do |child|
                assign_references(child)
              end
            end
          end
      end
    end
  end
end
