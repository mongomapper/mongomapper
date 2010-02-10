module MongoMapper
  module Plugins
    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      extend mod::ClassMethods     if mod.const_defined?(:ClassMethods)
      include mod::InstanceMethods if mod.const_defined?(:InstanceMethods)
      mod.configure(self)          if mod.respond_to?(:configure)
      plugins << mod
    end

    autoload :Callbacks,      'mongo_mapper/plugins/callbacks'
    autoload :Clone,          'mongo_mapper/plugins/clone'
    autoload :Descendants,    'mongo_mapper/plugins/descendants'
    autoload :Dirty,          'mongo_mapper/plugins/dirty'
    autoload :Equality,       'mongo_mapper/plugins/equality'
    autoload :IdentityMap,    'mongo_mapper/plugins/identity_map'
    autoload :Inspect,        'mongo_mapper/plugins/inspect'
    autoload :Keys,           'mongo_mapper/plugins/keys'
    autoload :Logger,         'mongo_mapper/plugins/logger'
    autoload :Protected,      'mongo_mapper/plugins/protected'
    autoload :Rails,          'mongo_mapper/plugins/rails'
    autoload :Serialization,  'mongo_mapper/plugins/serialization'
    autoload :Validations,    'mongo_mapper/plugins/validations'
  end
end

require 'mongo_mapper/plugins/associations'
require 'mongo_mapper/plugins/pagination'
