module MongoMapper
  module Plugins
    module Scopes
      module ClassMethods
        def scope(name, scope_options={})
          scopes[name] = lambda do |*args|
            options = scope_options.is_a?(Proc) ? scope_options.call(*args) : scope_options
            self.query(options)
          end

          singleton_class.send :define_method, name, &scopes[name]
        end

        def scopes
          @scopes ||= {}
        end
      end
    end
  end
end