# encoding: UTF-8
module MongoMapper
  module Plugins
    module Associations
      class ManyEmbeddedProxy < EmbeddedCollection
        def load_from_database(values)
          @_from_db = true
          @_values = (values || []).map do |v|
            v.respond_to?(:attributes) ? v.attributes : v
          end
          reset
        end

        def replace(values)
          @_from_db = false
          @_values = (values || []).map do |v|
            v.respond_to?(:attributes) ? v.attributes : v
          end
          reset
        end

        private
          def find_target
            if !@_from_db
              (@_values || []).map do |attrs|
                klass.new(attrs).tap do |child|
                  assign_references(child)
                end
              end
            else
              @_from_db = false
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
end
