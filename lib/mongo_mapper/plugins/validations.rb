# encoding: UTF-8
module MongoMapper
  module Plugins
    module Validations
      def self.configure(model)
        model.class_eval do
          include Validatable
          extend Validations::DocumentMacros
        end
      end

      module DocumentMacros
        def validates_uniqueness_of(*args)
          add_validations(args, Validations::ValidatesUniquenessOf)
        end
      end

      class ValidatesUniquenessOf < Validatable::ValidationBase
        option :scope, :case_sensitive
        default :case_sensitive => true

        def valid?(instance)
          value = instance[attribute]
          return allow_nil if value.nil? and not allow_nil.nil?
          return allow_blank if value.blank? and not allow_blank.nil?
          base_conditions = case_sensitive ? {self.attribute => value} : {}

          klass = instance.attributes['_type'].present? ? instance.class.collection.name.camelize.singularize.constantize : instance.class

          doc = klass.first(base_conditions.merge(scope_conditions(instance)).merge(where_conditions(instance)))
          doc.nil? || instance._id == doc._id
        end

        def message(instance)
          super || "has already been taken"
        end

        def scope_conditions(instance)
          return {} unless scope
          Array(scope).inject({}) do |conditions, key|
            conditions.merge(key => instance[key])
          end
        end

        def where_conditions(instance)
          conditions = {}
          conditions[attribute] = /^#{Regexp.escape(instance[attribute].to_s)}$/i unless case_sensitive
          conditions
        end
      end
    end
  end
end
