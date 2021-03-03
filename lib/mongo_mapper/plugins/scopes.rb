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

        def default_scopes
          @default_scopes ||= begin
            superclass.respond_to?(:default_scopes) ?
              superclass.default_scopes.dup :
              []
          end
        end

        # @param Hash options
        # @options options [Boolean] :unscoped Specify to return plain query object
        def query(options = {})
          if options.delete(:unscoped)
            context = super(options)
          else
            context = current_context

            if context
              context = process_scope(context, options)
            else
              context = super(options)

              default_scopes.flatten.each do |scope|
                context = process_scope(context, scope)
              end
            end
          end

          context
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

        def with_scope(scope = {})
          prev, self.current_context = current_context, process_scope(query, scope)
          yield
        ensure
          self.current_context = prev
        end

        def unscoped
          prev, self.current_context = current_context, query(unscoped: true)
          yield
        ensure
          self.current_context = prev
        end

      private

        def current_context
          Thread.current["mongo_mapper_#{name}_current_context"]
        end

        def current_context=(context)
          Thread.current["mongo_mapper_#{name}_current_context"] = context
        end

        def process_scope(context, scope, *args)
          if scope.is_a?(Proc)
            scope = context.instance_exec(*args, &scope)
          end

          scope.is_a?(Hash) ?
            context.where(scope) :
            scope
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
