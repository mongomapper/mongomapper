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
  end
end

require 'mongo_mapper/plugins/associations'
require 'mongo_mapper/plugins/callbacks'
require 'mongo_mapper/plugins/clone'
require 'mongo_mapper/plugins/descendants'
require 'mongo_mapper/plugins/dirty'
require 'mongo_mapper/plugins/equality'
require 'mongo_mapper/plugins/identity_map'
require 'mongo_mapper/plugins/inspect'
require 'mongo_mapper/plugins/keys'
require 'mongo_mapper/plugins/logger'
require 'mongo_mapper/plugins/pagination'
require 'mongo_mapper/plugins/protected'
require 'mongo_mapper/plugins/rails'
require 'mongo_mapper/plugins/serialization'
require 'mongo_mapper/plugins/validations'
