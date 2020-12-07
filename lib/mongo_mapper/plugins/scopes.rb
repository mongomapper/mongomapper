# encoding: UTF-8
module MongoMapper
  module Plugins
    module Scopes
      extend ActiveSupport::Concern

      included do
        class_attribute :_scopes
      end

      module ClassMethods
        def scope(name, scope={})
          if dangerous_class_method?(name)
            raise ArgumentError, <<~end_message
              You tried to define a scope named "#{name}"
              on the model "#{self.name}", but MongoMapper::Document already defined
              a class method with the same name.
            end_message
          end

          # Assign to _scopes instead of using []= to avoid mixing subclass scopes
          self._scopes = scopes.merge(name => scope)

          singleton_class.send :define_method, name do |*args|
            process_scope(self, scopes[name], *args)
          end
        end

        def scopes
          self._scopes ||= {}
        end

        def active_scopes
          Thread.current["mongo_mapper_#{name}_active_scopes"] ||= []
        end

        def default_scopes
          @default_scopes ||= begin
            superclass.respond_to?(:default_scopes) ?
              superclass.default_scopes.dup :
              []
          end
        end

        def query(options = {})
          res = super(options)

          all_anonymous_scopes.each do |scope|
            unscoped do
              res = process_scope(res, scope)
            end
          end

          res
        end

        def default_scope(*args, &block)
          if block_given?
            default_scopes << instance_exec(&block)
          end

          if args.any?
            default_scopes << args
          end

          default_scopes
        end

        def with_scope(query = {})
          active_scopes.push(query)
          yield
        ensure
          active_scopes.pop
        end

        def unscoped
          old_default_scopes = default_scopes.dup
          old_active_scopes = active_scopes.dup

          @default_scopes = []
          active_scopes.clear

          yield
        ensure
          @default_scopes = old_default_scopes
          active_scopes.concat(old_active_scopes)
        end

      private

        def process_scope(context, scope, *args)
          if scope.is_a?(Proc)
            scope = context.instance_exec(*args, &scope)
          end

          scope.is_a?(Hash) ?
            context.where(scope) :
            scope
        end

        def all_anonymous_scopes
          [default_scopes + active_scopes].flatten
        end

        RESTRICTED_CLASS_METHODS = %w(private public protected allocate new name parent superclass)
        private_constant :RESTRICTED_CLASS_METHODS

        def dangerous_class_method?(method_name)
          return true if RESTRICTED_CLASS_METHODS.include?(method_name.to_s)
          Document.method_defined?(method_name)
        end
      end
    end
  end
end
