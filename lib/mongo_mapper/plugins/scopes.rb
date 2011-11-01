# encoding: UTF-8
module MongoMapper
  module Plugins
    module Scopes
      extend ActiveSupport::Concern

      included do
        class_attribute :_scopes
      end

      module ClassMethods
        def scope(name, scope_options={})
          scopes[name] = lambda do |*args|
            result = scope_options.is_a?(Proc) ? scope_options.call(*args) : scope_options
            result = self.query(result) if result.is_a?(Hash)
            self.query.merge(result)
          end
          singleton_class.send :define_method, name, &scopes[name]
        end

        def scopes
          self._scopes || self._scopes = {}
        end
      end
    end
  end
end