# encoding: UTF-8
require 'plucky'
require 'active_support/core_ext'
require 'active_model'
require "mongo_mapper/railtie" if defined?(Rails)

I18n.load_path << File.expand_path('../mongo_mapper/locale/en.yml', __FILE__)

module MongoMapper
  autoload :Connection,             'mongo_mapper/connection'

  autoload :Error,                  'mongo_mapper/exceptions'
  autoload :DocumentNotFound,       'mongo_mapper/exceptions'
  autoload :InvalidScheme,          'mongo_mapper/exceptions'
  autoload :DocumentNotValid,       'mongo_mapper/exceptions'
  autoload :AccessibleOrProtected,  'mongo_mapper/exceptions'

  autoload :Document,               'mongo_mapper/document'
  autoload :EmbeddedDocument,       'mongo_mapper/embedded_document'
  autoload :Plugins,                'mongo_mapper/plugins'
  autoload :Translation,            'mongo_mapper/translation'
  autoload :Version,                'mongo_mapper/version'

  module Middleware
    autoload :IdentityMap, 'mongo_mapper/middleware/identity_map'
  end

  module Plugins
    autoload :ActiveModel,        'mongo_mapper/plugins/active_model'
    autoload :Associations,       'mongo_mapper/plugins/associations'
    autoload :Accessible,         'mongo_mapper/plugins/accessible'
    autoload :Callbacks,          'mongo_mapper/plugins/callbacks'
    autoload :Caching,            'mongo_mapper/plugins/caching'
    autoload :Clone,              'mongo_mapper/plugins/clone'
    autoload :Dirty,              'mongo_mapper/plugins/dirty'
    autoload :Document,           'mongo_mapper/plugins/document'
    autoload :DynamicQuerying,    'mongo_mapper/plugins/dynamic_querying'
    autoload :EmbeddedCallbacks,  'mongo_mapper/plugins/embedded_callbacks'
    autoload :EmbeddedDocument,   'mongo_mapper/plugins/embedded_document'
    autoload :Equality,           'mongo_mapper/plugins/equality'
    autoload :IdentityMap,        'mongo_mapper/plugins/identity_map'
    autoload :Inspect,            'mongo_mapper/plugins/inspect'
    autoload :Indexes,            'mongo_mapper/plugins/indexes'
    autoload :Keys,               'mongo_mapper/plugins/keys'
    autoload :Logger,             'mongo_mapper/plugins/logger'
    autoload :Modifiers,          'mongo_mapper/plugins/modifiers'
    autoload :Pagination,         'mongo_mapper/plugins/pagination'
    autoload :Persistence,        'mongo_mapper/plugins/persistence'
    autoload :Protected,          'mongo_mapper/plugins/protected'
    autoload :Querying,           'mongo_mapper/plugins/querying'
    autoload :Rails,              'mongo_mapper/plugins/rails'
    autoload :Safe,               'mongo_mapper/plugins/safe'
    autoload :Sci,                'mongo_mapper/plugins/sci'
    autoload :Scopes,             'mongo_mapper/plugins/scopes'
    autoload :Serialization,      'mongo_mapper/plugins/serialization'
    autoload :Timestamps,         'mongo_mapper/plugins/timestamps'
    autoload :Userstamps,         'mongo_mapper/plugins/userstamps'
    autoload :Validations,        'mongo_mapper/plugins/validations'
    autoload :Touch,              'mongo_mapper/plugins/touch'

    module Associations
      autoload :Base,                         'mongo_mapper/plugins/associations/base'
      autoload :Collection,                   'mongo_mapper/plugins/associations/collection'
      autoload :EmbeddedCollection,           'mongo_mapper/plugins/associations/embedded_collection'
      autoload :ManyAssociation,              'mongo_mapper/plugins/associations/many_association'
      autoload :SingleAssociation,            'mongo_mapper/plugins/associations/single_association'
      autoload :BelongsToAssociation,         'mongo_mapper/plugins/associations/belongs_to_association'
      autoload :OneAssociation,               'mongo_mapper/plugins/associations/one_association'
      autoload :ManyDocumentsProxy,           'mongo_mapper/plugins/associations/many_documents_proxy'
      autoload :BelongsToProxy,               'mongo_mapper/plugins/associations/belongs_to_proxy'
      autoload :BelongsToPolymorphicProxy,    'mongo_mapper/plugins/associations/belongs_to_polymorphic_proxy'
      autoload :ManyPolymorphicProxy,         'mongo_mapper/plugins/associations/many_polymorphic_proxy'
      autoload :ManyEmbeddedProxy,            'mongo_mapper/plugins/associations/many_embedded_proxy'
      autoload :ManyEmbeddedPolymorphicProxy, 'mongo_mapper/plugins/associations/many_embedded_polymorphic_proxy'
      autoload :ManyDocumentsAsProxy,         'mongo_mapper/plugins/associations/many_documents_as_proxy'
      autoload :OneProxy,                     'mongo_mapper/plugins/associations/one_proxy'
      autoload :OneAsProxy,                   'mongo_mapper/plugins/associations/one_as_proxy'
      autoload :OneEmbeddedProxy,             'mongo_mapper/plugins/associations/one_embedded_proxy'
      autoload :OneEmbeddedPolymorphicProxy,  'mongo_mapper/plugins/associations/one_embedded_polymorphic_proxy'
      autoload :InArrayProxy,                 'mongo_mapper/plugins/associations/in_array_proxy'
    end
  end

  extend Connection
end

Dir[File.join(File.dirname(__FILE__), 'mongo_mapper', 'extensions', '*.rb')].each do |extension|
  require extension
end

# FIXME: autoload with proxy is failing, need to investigate
require 'mongo_mapper/plugins/associations/proxy'

ActiveSupport.run_load_hooks(:mongo_mapper, MongoMapper)
