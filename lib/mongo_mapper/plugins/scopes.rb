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
          # Dup so :unscoped can be removed without mutating a hash the caller
          # still holds, and so a frozen hash does not raise.
          options = options.dup

          if options.delete(:unscoped)
            super(options)
          elsif (context = current_context)
            # with_scope / unscoped already captured default and active criteria
            # on this query. amend applies both criteria and query options
            # (limit, sort, ...) the same way Querying#query does. where()
            # would fold those options into the criteria hash.
            context.clone.amend(options)
          elsif applying_default_scopes?
            # A default scope is running and called back into query. Applying
            # default scopes again recurses. Skip them for this call only.
            # The previous implementation cleared the shared @default_scopes
            # array to get the same effect, which other threads could observe.
            super(options)
          else
            apply_default_scopes(super(options))
          end
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

        def applying_default_scopes_key
          "mongo_mapper_#{name}_applying_default_scopes"
        end

        def applying_default_scopes?
          Thread.current[applying_default_scopes_key]
        end

        def apply_default_scopes(context)
          key = applying_default_scopes_key
          previous = Thread.current[key]
          Thread.current[key] = true

          default_scopes.flatten.each do |scope|
            context = process_scope(context, scope)
          end

          context
        ensure
          Thread.current[key] = previous
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
